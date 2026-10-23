import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/watch/view_models/watched_apps_view_model.dart';
import 'package:doomread/ui/watch/widgets/watch_disclosure.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Which apps bring up the "not yet" screen, and, while the service is off,
/// the way to turn it on through the disclosure.
class WatchedAppsScreen extends StatelessWidget {
  const WatchedAppsScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => WatchedAppsViewModel(c.read(), c.read()),
    child: const _WatchedApps(),
  );
}

class _WatchedApps extends StatelessWidget {
  const _WatchedApps();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<WatchedAppsViewModel>();
    final apps = vm.apps;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.watchedApps)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(l10n.watchedAppsHint, style: text.bodyMedium),
          ),
          if (vm.grants case final g? when vm.method != .accessibility)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _WatchCard(vm: vm, grants: g),
            ),
          for (final a in apps)
            CheckboxListTile(
              value: vm.watched(a.package),
              title: Text(a.label),
              onChanged: (on) => vm.setWatched(a.package, on: on!),
            ),
        ],
      ),
    );
  }
}

/// How apps are watched while Accessibility is off: the way to turn it on,
/// and the slower usage access fallback (ADR 0016).
class _WatchCard extends StatelessWidget {
  const _WatchCard({required this.vm, required this.grants});

  final WatchedAppsViewModel vm;
  final WatchGrants grants;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final mute = text.bodySmall!.copyWith(color: Palette.mute);
    final usage = vm.method == WatchMethod.usageAccess;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.panel,
        border: Border.all(color: Palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              usage ? l10n.watchOnUsage : l10n.watchOff,
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            // Android 13+ restricts it for sideloaded apps.
            Text(l10n.watchRestricted, style: mute),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () async {
                  if (await askToWatch(context)) await vm.openSettings();
                },
                child: Text(l10n.watchTurnOn),
              ),
            ),
            if (!usage) ...[
              const Divider(color: Palette.line),
              const SizedBox(height: 8),
              Text(l10n.watchFallback, style: mute),
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  if (!grants.usageAccess)
                    TextButton(
                      onPressed: vm.openUsageAccess,
                      child: Text(l10n.watchAllowUsage),
                    ),
                  if (!grants.overlay)
                    TextButton(
                      onPressed: vm.openOverlay,
                      child: Text(l10n.watchAllowOverlay),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
