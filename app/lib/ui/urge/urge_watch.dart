import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

/// Hears which app comes to the front during a Session and raises the Urge
/// when core says it's a Watched app. The Urge itself is a journal event,
/// and Reading shows it from the journal, so after a restart an Urge left
/// open is still there.
class UrgeWatch {
  UrgeWatch(this._sessions, this._watch, this._settings) {
    _sub = _sessions.watchAll().listen((all) {
      _all = all;
      _sync();
    });
    _settings.addListener(_sync);
    _watch.onForeground = _foreground;
    // The user grants Accessibility or usage access in the system settings,
    // so the way to watch can change while the app is away.
    _lifecycle = AppLifecycleListener(onResume: _sync);
  }

  final SessionRepository _sessions;
  final AppWatch _watch;
  final SettingsViewModel _settings;
  late final StreamSubscription<List<SessionRecord>> _sub;
  late final AppLifecycleListener _lifecycle;
  List<SessionRecord>? _all;

  /// Called with the Session to show when an Urge comes up.
  void Function(String sessionId)? onUrge;

  /// The app that raised the Urge showing now, for "Open it anyway"; null
  /// when the app was restarted since.
  LaunchableApp? get app => _app;
  LaunchableApp? _app;

  /// An app reported before the journal loaded, say when the service
  /// started Doomread to hear it.
  (String, String, Set<String>)? _pending;

  /// What was last told to the service: whether to watch, the Work app
  /// whose views to look for, and whether to poll usage access.
  (bool, String?, bool)? _told;

  /// The Session that just slipped, until the journal shows it: the app it
  /// opens reports before then, and mustn't bring the Urge back.
  String? _slipping;

  /// The most recent open Session, whatever its Work.
  SessionRecord? _open(List<SessionRecord> all, DateTime now) => all.reversed
      .where((r) => r.at(now).startedAt != null && !r.at(now).stopped)
      .firstOrNull;

  void _sync() {
    final all = _all;
    if (all == null) return;
    final now = _sessions.now();
    if (all.where((r) => r.id == _slipping).firstOrNull case final r?
        when !r.at(now).urgeOpen) {
      _slipping = null;
    }
    final open = _open(all, now);
    final rules = open == null ? null : _settings.watchRules(open.road.work.id);
    unawaited(_tell(open != null, rules));
    if (_pending case (final package, final label, final views)?) {
      _pending = null;
      _foreground(package, label, views);
    }
  }

  /// Counts calls to [_tell], so a slow one can't overwrite a later one.
  int _telling = 0;

  Future<void> _tell(bool on, WatchRules? rules) async {
    final call = ++_telling;
    final poll = on && await _watch.method() == WatchMethod.usageAccess;
    if (call != _telling) return;
    final told = (on, rules?.workApp, poll);
    if (told == _told) return;
    _told = told;
    await _watch.setWatching(
      on: on,
      views: rules?.views ?? const {},
      poll: poll,
    );
  }

  void _foreground(String package, String label, Set<String> views) {
    final all = _all;
    // Not before the user's own Watched apps have loaded, either.
    if (all == null || !_settings.loaded) {
      _pending = (package, label, views);
      return;
    }
    unawaited(_raise(all, package, label, views));
  }

  Future<void> _raise(
    List<SessionRecord> all,
    String package,
    String label,
    Set<String> views,
  ) async {
    final now = _sessions.now();
    final open = _open(all, now);
    if (open == null || open.id == _slipping) return;
    final session = open.at(now);
    final rules = _settings.watchRules(open.road.work.id);
    if (raisesUrge(session, package, rules, views)) {
      await _sessions.add(open, SessionEventKind.urge);
    } else if (!bringsUrgeBack(session, package, rules, views)) {
      return;
    }
    // Shorts is named for itself, not for YouTube.
    _app = (
      package: package,
      label: rules.screen(package, views)?.name ?? label,
    );
    onUrge?.call(open.id);
    await _watch.bringToFront();
  }

  /// Open anyway: records the Slip, then opens the app that raised the
  /// Urge, if it's known.
  Future<void> slip(SessionRecord record) async {
    _slipping = record.id;
    await _sessions.add(record, SessionEventKind.slip);
    if (_app case final a?) await _watch.open(a.package);
  }

  void dispose() {
    _lifecycle.dispose();
    _watch.onForeground = null;
    _settings.removeListener(_sync);
    unawaited(_sub.cancel());
  }
}
