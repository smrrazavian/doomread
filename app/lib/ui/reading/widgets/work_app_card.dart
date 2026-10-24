import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Asks where [workId] is tonight and keeps the answer for its next
/// Sessions: its Work app, or none when it isn't on the phone. A dismissed
/// sheet changes nothing.
Future<void> pickWorkApp(BuildContext context, String workId) async {
  final settings = context.read<SettingsViewModel>();
  final apps = await context.read<AppWatch>().apps();
  if (!context.mounted) return;
  // A record, so "not on the phone" (null) differs from a dismissed sheet.
  final picked = await showModalBottomSheet<(LaunchableApp?,)>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WorkAppSheet(apps: apps),
  );
  if (picked != null) await settings.setWorkApp(workId, picked.$1);
}

// ponytail: a guess from package names, not a catalogue. Ebook readers,
// YouTube, podcast and streaming apps come up first; the rest by label.
const _likely = [
  'youtube',
  'kindle',
  'books',
  'reader',
  'kobo',
  'fidibo',
  'taaghche',
  'podcast',
  'antennapod',
  'castbox',
  'audible',
  'spotify',
  'pocketcasts',
  'netflix',
  'filimo',
  'namava',
];

/// The apps the picker lists for [query]: those whose label holds it, the
/// likely Work apps first, then by label.
List<LaunchableApp> _choices(List<LaunchableApp> apps, String query) {
  final q = query.trim().toLowerCase();
  int rank(LaunchableApp a) => _likely.any(a.package.contains) ? 0 : 1;
  return [
    for (final a in apps)
      if (a.label.toLowerCase().contains(q)) a,
  ]..sort((a, b) {
    final r = rank(a) - rank(b);
    return r != 0 ? r : a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
}

/// "Turn the phone face down", unless the Work is in an app on the phone,
/// its Work app: then the way to it. The user says which app here, where
/// it matters, and it's kept for the Work's next Sessions.
class WorkAppCard extends StatelessWidget {
  const WorkAppCard({required this.workId, super.key});

  final String workId;

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
        onTap: watch.available ? () => pickWorkApp(context, workId) : null,
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
                    onPressed: () => pickWorkApp(context, workId),
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

class _WorkAppSheet extends StatefulWidget {
  const _WorkAppSheet({required this.apps});

  final List<LaunchableApp> apps;

  @override
  State<_WorkAppSheet> createState() => _WorkAppSheetState();
}

class _WorkAppSheetState extends State<_WorkAppSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final shown = _choices(widget.apps, _query);
    // Above the keyboard while searching, and never taller than most of
    // the screen, so the list shrinks instead of overflowing.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
                child: Text(l10n.workAppPick, style: text.titleMedium),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: Text(l10n.workAppHint, style: text.bodySmall),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.whereIsSearch,
                    isDense: true,
                  ),
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mobile_off),
                title: Text(l10n.workAppNone),
                onTap: () => Navigator.pop(context, (null,)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final a in shown)
                      ListTile(
                        leading: const Icon(Icons.apps),
                        title: Text(a.label),
                        onTap: () => Navigator.pop(context, (a,)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
