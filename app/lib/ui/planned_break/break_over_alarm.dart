import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/services/break_over_notification.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';

/// Keeps the "break's over" notification in step with the journal: set for
/// the end of the Planned break the user is on, and unset once they're back
/// or have stopped.
///
/// Like the Session notification, it reads nothing but the journal and the
/// clock, so it's right again after the app was killed and started.
class BreakOverAlarm {
  BreakOverAlarm(this._sessions, this._notification, this._settings) {
    _sub = _sessions.watchAll().listen((all) {
      _all = all;
      _sync();
    });
    _settings.addListener(_sync);
  }

  final SessionRepository _sessions;
  final BreakOverNotification _notification;
  final SettingsViewModel _settings;
  late final StreamSubscription<List<SessionRecord>> _sub;
  List<SessionRecord>? _all;

  /// What was last set, so an unchanged journal sends nothing; false once
  /// unset.
  Object? _last;

  void _sync() {
    final all = _all;
    if (all == null) return;
    final now = _sessions.now();
    final onBreak = all.reversed.where((r) => r.at(now).onBreak).firstOrNull;
    final offer = onBreak == null ? null : plannedBreakOf(onBreak, all, now);
    if (onBreak == null || offer == null) {
      if (_last != false) unawaited(_notification.cancel());
      _last = false;
      return;
    }

    final at = onBreak.at(now).breaks.last.start.add(offer.length);
    final l10n = lookupAppLocalizations(_settings.locale);
    final work = onBreak.road.work;
    final checkpoint = offer.checkpoint;
    final text = checkpoint == null
        ? l10n.workWaiting(work.title)
        : l10n.chapterWaiting(chapterEndingAt(work, checkpoint) + 1);
    final set = (onBreak.id, at, text);
    if (set == _last) return;
    _last = set;
    // Once the time has passed there's nothing left to call them back for.
    if (!at.isAfter(now)) return;
    unawaited(
      _notification.schedule(
        sessionId: onBreak.id,
        at: at,
        title: l10n.breakOver,
        text: text,
      ),
    );
  }

  void dispose() {
    _settings.removeListener(_sync);
    unawaited(_sub.cancel());
  }
}
