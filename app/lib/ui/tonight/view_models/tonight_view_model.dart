import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/data/services/session_notification.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

class TonightViewModel extends ChangeNotifier {
  TonightViewModel(
    WorkRepository works,
    this._sessions,
    this._settings,
    this._notification,
    this._watch,
  ) {
    start = Command0(_start);
    _subs = [
      works.watchCurrent().listen((r) {
        _road = r;
        _loaded = true;
        notifyListeners();
      }),
      _sessions.watchAll().listen((all) {
        _history = all;
        notifyListeners();
      }),
    ];
  }

  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final SessionNotification _notification;
  final AppWatch _watch;
  late final List<StreamSubscription<Object?>> _subs;
  List<SessionRecord> _history = const [];

  /// The current Work on its Road; null when there's no Work yet.
  Road? get road => _road;
  Road? _road;

  bool get loaded => _loaded;
  bool _loaded = false;

  /// Starts a Session with the current Work; its result is the Session's id.
  late final Command0<String> start;

  /// Tonight's Aim: the Longest stretch plus one minute, for reading or for
  /// watching, whichever the current Work is.
  Duration get aim => aimAfter(
    measured(_history, _sessions.now()),
    watched: road?.work.kind.watched ?? false,
  );

  /// About how many evenings until the Finish; null until there's a pace.
  int? get evenings {
    final road = this.road;
    return road == null
        ? null
        : eveningsLeftOn(road, measured(_history, _sessions.now()));
  }

  /// This week's nights, lit where any Session started, in a week that
  /// starts on [firstDay] (see [firstDayOfWeek]).
  ReadingWeek readingWeek(int firstDay) {
    final now = _sessions.now();
    return ReadingWeek(
      now: now,
      firstDay: firstDay,
      sessionStarts: [for (final r in _history) ?r.at(now).startedAt],
    );
  }

  /// A Session with the current Work that was never stopped, say because the
  /// app was closed during it. Tonight offers to go back to it.
  String? get openSession {
    final now = _sessions.now();
    for (final r in _history.reversed) {
      if (r.road.work.id == road?.work.id && !r.at(now).stopped) return r.id;
    }
    return null;
  }

  /// Whether to explain the Session notification before this Start: only
  /// the first time, and only where the system would still ask.
  Future<bool> shouldExplainNotification() async =>
      !await _settings.notificationsAsked() && await _notification.canAsk();

  /// Remembers that the user answered the explanation, and on yes shows the
  /// system prompt. Either way they aren't asked again.
  Future<void> answerNotification({required bool allow}) async {
    await _settings.setNotificationsAsked();
    if (allow) await _notification.ask();
  }

  /// Whether to offer the "not yet" screen before this Start: once, and
  /// only where it can be turned on and isn't yet.
  Future<bool> shouldOfferWatch() async =>
      _watch.available &&
      !await _settings.watchAsked() &&
      !await _watch.enabled();

  /// Remembers the offer was answered, and on yes opens the system's
  /// Accessibility settings. Either way the Session starts.
  Future<void> answerWatch({required bool agree}) async {
    await _settings.setWatchAsked();
    if (agree) await _watch.openSettings();
  }

  Future<Result<String>> _start() async =>
      Result.ok(openSession ?? await _sessions.start(road!.work.id));

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
