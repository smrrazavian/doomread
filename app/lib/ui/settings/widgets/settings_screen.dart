import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/ui/tone/widgets/tone_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Each language is named in itself, so it can be found from either side.
  static const _languages = {'en': 'English', 'fa': 'فارسی'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: RadioGroup<String>(
        groupValue: vm.locale.languageCode,
        onChanged: (code) => vm.setLocale(Locale(code!)),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.account),
              onTap: () => context.push('/account'),
            ),
            ListTile(
              leading: const Icon(Icons.record_voice_over_outlined),
              title: Text(l10n.tone),
              subtitle: Text(toneName(l10n, vm.tone)),
              onTap: () => context.push('/tone'),
            ),
            if (context.read<AppWatch>().available) const _WatchedAppsTile(),
            ListTile(
              key: const Key('replayIntro'),
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(l10n.tourReplay),
              onTap: () => context.push('/intro?replay'),
            ),
            ListTile(title: Text(l10n.language)),
            for (final MapEntry(:key, :value) in _languages.entries)
              RadioListTile<String>(value: key, title: Text(value)),
          ],
        ),
      ),
    );
  }
}

/// Watched apps, with which way of watching is on, looked at again when the
/// user comes back from it or from the system settings.
class _WatchedAppsTile extends StatefulWidget {
  const _WatchedAppsTile();

  @override
  State<_WatchedAppsTile> createState() => _WatchedAppsTileState();
}

class _WatchedAppsTileState extends State<_WatchedAppsTile> {
  late final AppLifecycleListener _lifecycle;
  late Future<WatchMethod?> _method;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _method = context.read<AppWatch>().method();
  }

  void _refresh() {
    final method = context.read<AppWatch>().method();
    setState(() {
      _method = method;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: _method,
      builder: (context, snap) => ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(l10n.watchedApps),
        subtitle: snap.connectionState == ConnectionState.done
            ? Text(switch (snap.data) {
                WatchMethod.accessibility => l10n.watchViaAccessibility,
                WatchMethod.usageAccess => l10n.watchViaUsage,
                null => l10n.watchViaNone,
              })
            : null,
        onTap: () async {
          await context.push('/watched');
          if (mounted) _refresh();
        },
      ),
    );
  }
}
