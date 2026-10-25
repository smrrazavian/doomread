import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/evening/widgets/evening_screen.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// One Session at a time: before one starts on [workId], asks to stop the
/// one running on another Work, if any. True when the new one can start.
///
/// A Task's Session just stops. A book's, a film's or a podcast's goes on
/// to its End of the evening, for the Position and the Note, so the new
/// one waits for the next Start.
Future<bool> stopOtherSessionFirst(BuildContext context, String workId) async {
  final sessions = context.read<SessionRepository>();
  final other = await sessions.runningElsewhere(workId);
  if (other == null) return true;
  if (!context.mounted) return false;
  final stop = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        backgroundColor: Palette.panel,
        title: Text(l10n.oneSessionTitle(other.road.work.title)),
        content: Text(l10n.oneSessionBody),
        actions: [
          TextButton(
            key: const Key('oneSessionNotNow'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.oneSessionNotNow),
          ),
          FilledButton(
            key: const Key('oneSessionStop'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.oneSessionStop),
          ),
        ],
      );
    },
  );
  if (stop != true) return false;
  await sessions.add(other, SessionEventKind.stop);
  if (other.road.work.kind == WorkKind.task) return true;
  if (context.mounted) unawaited(context.push(eveningPath(other.id)));
  return false;
}

/// Opens the Session [sessionId], and the first time the user leaves one
/// running with back, says it keeps running.
Future<void> openSession(BuildContext context, String sessionId) async {
  await context.push<void>('/reading/$sessionId');
  if (!context.mounted) return;
  final sessions = context.read<SessionRepository>();
  final record = (await sessions.all())
      .where((r) => r.id == sessionId)
      .firstOrNull;
  if (record == null || record.at(sessions.now()).stopped) return;
  if (!context.mounted) return;
  final settings = context.read<SettingsRepository>();
  if (await settings.keepsRunningSaid() || !context.mounted) return;
  unawaited(settings.setKeepsRunningSaid());
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _overTheButton(Text(AppLocalizations.of(context).sessionKeepsRunning)),
    );
}

/// Right after a Stop: "Stopped by mistake? Resume", where Resume is
/// [resume]: take the Stop back and go back to the Session.
void offerReopen(BuildContext context, Future<void> Function() resume) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _overTheButton(
        Text(l10n.stoppedByMistake),
        action: SnackBarAction(
          label: l10n.resume,
          onPressed: () => unawaited(resume()),
        ),
      ),
    );
}

/// A snackbar floating over the button at the bottom of Today and of End
/// of the evening, so it never covers it.
SnackBar _overTheButton(Widget content, {SnackBarAction? action}) => SnackBar(
  content: content,
  action: action,
  persist: false,
  behavior: SnackBarBehavior.floating,
  margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
);
