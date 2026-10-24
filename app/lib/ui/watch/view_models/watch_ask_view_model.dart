import 'dart:async';

import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:flutter/widgets.dart';

/// How the "not yet" screen was when the user came back from the system's
/// Accessibility settings.
enum WatchReturn { on, off }

/// The one way the app asks for the "not yet" screen, app-wide: whether
/// the ask is still due, the ask itself (the disclosure, then the system
/// settings), and what the user did there, read when they come back.
class WatchAskViewModel extends ChangeNotifier {
  WatchAskViewModel(this._settings, this._watch) {
    ask = Command1(_ask);
    retry = Command0(_retry);
    _lifecycle = AppLifecycleListener(
      onHide: _left,
      onPause: _left,
      onResume: _back,
    );
    unawaited(_refresh());
  }

  final SettingsRepository _settings;
  final AppWatch _watch;
  late final AppLifecycleListener _lifecycle;
  var _disposed = false;

  /// Whether the ask is still to come: once, only where apps can be watched
  /// and no way to watch is on yet.
  bool get due => _due;
  bool _due = false;

  /// What the user did in the settings, once a return has read it; the app
  /// says so, then calls [clearReturned].
  WatchReturn? get returned => _returned;
  WatchReturn? _returned;

  /// Asks: first marks it asked, so nothing else on screen asks it too,
  /// then shows the disclosure it's given (an affirmative tap, as Play asks)
  /// and on yes opens the system's Accessibility settings.
  late final Command1<void, Future<bool> Function()> ask;

  /// Opens the Accessibility settings again, after "still off".
  late final Command0<void> retry;

  /// Sent to the settings and not yet back with an answer read.
  var _waiting = false;

  /// Whether the app has really left for the settings since; a resume
  /// without leaving (a dialog closing) isn't the user coming back.
  var _away = false;
  var _reading = false;

  /// The user said "Not now", where they could.
  Future<void> answered() async {
    _due = false;
    notifyListeners();
    await _settings.setWatchAsked();
  }

  void clearReturned() => _returned = null;

  Future<Result<void>> _ask(Future<bool> Function() disclose) async {
    await answered();
    if (await disclose()) await _open();
    return const Result.ok(null);
  }

  Future<Result<void>> _retry() async {
    await _open();
    return const Result.ok(null);
  }

  Future<void> _open() async {
    _waiting = true;
    _away = false;
    await _watch.openSettings();
  }

  void _left() => _away = true;

  void _back() {
    unawaited(_refresh());
    if (_waiting && _away && !_reading) unawaited(_read());
  }

  /// Reads what's granted. Only a read that completes ends the wait; one
  /// that fails leaves it for the next return.
  Future<void> _read() async {
    _reading = true;
    try {
      final on = (await _watch.grants()).accessibility;
      if (_disposed) return;
      _waiting = false;
      _returned = on ? WatchReturn.on : WatchReturn.off;
      notifyListeners();
    } on Exception {
      // Still waiting: the next return reads again.
    } finally {
      _reading = false;
    }
  }

  Future<void> _refresh() async {
    final due =
        _watch.available &&
        !await _settings.watchAsked() &&
        await _watch.method() == null;
    if (_disposed || due == _due) return;
    _due = due;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    super.dispose();
  }
}
