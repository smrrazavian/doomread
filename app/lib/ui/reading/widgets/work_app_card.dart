import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Turn the phone face down", unless the Work is in an app on the phone,
/// its Work app: then the way to it. The user says which app here, where
/// it matters, and it's kept for the Work's next Sessions.
class WorkAppCard extends StatelessWidget {
  const WorkAppCard({required this.workId, super.key});

  final String workId;

  Future<void> _pick(BuildContext context) async {
    final settings = context.read<SettingsViewModel>();
    final apps = await context.read<AppWatch>().apps();
    if (!context.mounted) return;
    // A record, so "not on the phone" (null) differs from a dismissed sheet.
    final picked = await showModalBottomSheet<(LaunchableApp?,)>(
      context: context,
      builder: (_) => _WorkAppSheet(apps: apps),
    );
    if (picked != null) await settings.setWorkApp(workId, picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final watch = context.read<AppWatch>();
    final app = context.watch<SettingsViewModel>().workApps[workId];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.panel,
        border: Border.all(color: Palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: watch.available ? () => _pick(context) : null,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            16,
            8,
            watch.available ? 8 : 16,
            8,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                const Icon(Icons.phone_android, color: Palette.mute),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    app == null
                        ? l10n.faceDown
                        : l10n.workAppReading(app.label),
                    style: text.bodySmall,
                  ),
                ),
                if (app != null)
                  TextButton(
                    onPressed: () => watch.open(app.package),
                    child: Text(l10n.openWorkApp),
                  )
                else if (watch.available)
                  TextButton(
                    onPressed: () => _pick(context),
                    child: Text(l10n.workAppAsk),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkAppSheet extends StatelessWidget {
  const _WorkAppSheet({required this.apps});

  final List<LaunchableApp> apps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final sorted = [...apps]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
            child: Text(l10n.workAppPick, style: text.titleMedium),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(l10n.workAppHint, style: text.bodySmall),
          ),
          ListTile(
            leading: const Icon(Icons.mobile_off),
            title: Text(l10n.workAppNone),
            onTap: () => Navigator.pop(context, (null,)),
          ),
          for (final a in sorted)
            ListTile(
              leading: const Icon(Icons.apps),
              title: Text(a.label),
              onTap: () => Navigator.pop(context, (a,)),
            ),
        ],
      ),
    );
  }
}
