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

/// The first time the user leaves a running Session with back, says it
/// keeps running. Called as Reading closes, so it holds however that
/// Reading was opened.
void sayKeepsRunning(BuildContext context) {
  final settings = context.read<SettingsRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final text = AppLocalizations.of(context).sessionKeepsRunning;
  unawaited(() async {
    if (await settings.keepsRunningSaid()) return;
    unawaited(settings.setKeepsRunningSaid());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_overTheButton(Text(text)));
  }());
}

/// Right after a Stop: "Stopped by mistake? Resume", where Resume is
/// [resume]: take the Stop back and go back to the Session [sessionId].
/// One Session at a time holds here too, so Resume first asks to stop one
/// started since.
void offerReopen(
  BuildContext context,
  String sessionId,
  Future<void> Function() resume,
) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _overTheButton(
        Text(l10n.stoppedByMistake),
        action: SnackBarAction(
          label: l10n.resume,
          onPressed: () => unawaited(() async {
            final record = await context.read<SessionRepository>().byId(
              sessionId,
            );
            if (record == null || !context.mounted) return;
            if (await stopOtherSessionFirst(context, record.road.work.id)) {
              await resume();
            }
          }()),
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
