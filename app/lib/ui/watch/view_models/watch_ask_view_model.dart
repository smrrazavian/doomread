import 'dart:async';

import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:flutter/widgets.dart';

/// Whether to ask for the "not yet" screen (the Accessibility disclosure):
/// once, only where apps can be watched and no way to watch is on yet.
/// Looked at again when the user comes back from the system settings.
class WatchAskViewModel extends ChangeNotifier {
  WatchAskViewModel(this._settings, this._watch) {
    unawaited(_refresh());
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(_refresh()));
  }

  final SettingsRepository _settings;
  final AppWatch _watch;
  late final AppLifecycleListener _lifecycle;
  var _disposed = false;

  /// Whether the ask is still to come.
  bool get due => _due;
  bool _due = false;

  Future<void> _refresh() async {
    final due =
        _watch.available &&
        !await _settings.watchAsked() &&
        await _watch.method() == null;
    if (_disposed || due == _due) return;
    _due = due;
    notifyListeners();
  }

  /// The user answered, whatever the answer: it isn't asked again.
  Future<void> answered() async {
    _due = false;
    notifyListeners();
    await _settings.setWatchAsked();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    super.dispose();
  }
}
