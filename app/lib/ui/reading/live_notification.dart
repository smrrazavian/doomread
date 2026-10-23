import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/services/session_notification.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread_core/doomread_core.dart';

/// Keeps the Session notification in step with the journal: shown from Start
/// to Stop, in the app's language.
///
/// It reads nothing but the journal and the clock, so when the app starts
/// again after it was killed, the notification comes back exactly as the
/// journal left it, with the running Stretch still counted from its start.
class LiveNotification {
  LiveNotification(this._sessions, this._notification, this._settings) {
    _sub = _sessions.watchAll().listen((all) {
      _all = all;
      _sync();
    });
    _settings.addListener(_sync);
  }

  final SessionRepository _sessions;
  final SessionNotification _notification;
  final SettingsViewModel _settings;
  late final StreamSubscription<List<SessionRecord>> _sub;
  List<SessionRecord>? _all;

  /// What was last sent, so an unchanged journal sends nothing.
  Object? _last;

  void _sync() {
    final all = _all;
    if (all == null) return;
    final now = _sessions.now();
    // The most recent open Session, whatever its Work.
    final open = all.reversed
        .where((r) => r.at(now).startedAt != null && !r.at(now).stopped)
        .firstOrNull;
    if (open == null) {
      if (_last != false) unawaited(_notification.cancel());
      _last = false;
      return;
    }

    final session = open.at(now);
    final locale = _settings.locale;
    final l10n = lookupAppLocalizations(locale);
    final running = session.current;
    final String text;
    if (running != null) {
      final before = all.where((r) => r.id != open.id).map((r) => r.at(now));
      text = l10n.aim(aimFor(longestStretch(before)).inMinutes);
    } else if (session.onBreak) {
      text = l10n.onBreak;
    } else {
      final last = session.stretches.lastOrNull?.length ?? Duration.zero;
      text = l10n.notificationPaused(formatClock(last, locale));
    }
    final shown = (open.id, open.road.work.title, text, running?.start);
    if (shown == _last) return;
    _last = shown;
    unawaited(
      _notification.show(
        sessionId: open.id,
        title: open.road.work.title,
        text: text,
        runningSince: running?.start,
      ),
    );
  }

  void dispose() {
    _settings.removeListener(_sync);
    unawaited(_sub.cancel());
  }
}
