import 'dart:async';

import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/widgets.dart';

/// The Watched apps: which way of watching is on, and which apps it
/// watches.
class WatchedAppsViewModel extends ChangeNotifier {
  WatchedAppsViewModel(this._watch, this._settings) {
    _settings.addListener(notifyListeners);
    // The user turns the service on in the system settings, so look again
    // when they come back.
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
    unawaited(refresh());
  }

  final AppWatch _watch;
  final SettingsViewModel _settings;
  late final AppLifecycleListener _lifecycle;
  bool _disposed = false;

  /// What the user has granted; null until known.
  WatchGrants? get grants => _grants;
  WatchGrants? _grants;

  /// The way apps are watched now; null until known or when none is on.
  WatchMethod? get method => switch (_grants) {
    final g? => pickWatchMethod(g),
    null => null,
  };

  /// The launchable apps, the Watched ones first, then by label.
  List<LaunchableApp> get apps {
    int rank(LaunchableApp a) => watched(a.package) ? 0 : 1;
    return [..._apps]..sort((a, b) {
      final r = rank(a) - rank(b);
      return r != 0
          ? r
          : a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
  }

  List<LaunchableApp> _apps = const [];

  bool watched(String package) => _settings.watched.contains(package);

  Future<void> setWatched(String package, {required bool on}) =>
      _settings.setWatched(package, on: on);

  Future<void> openSettings() => _watch.openSettings();

  Future<void> openUsageAccess() => _watch.openUsageAccess();

  Future<void> openOverlay() => _watch.openOverlay();

  Future<void> refresh() async {
    final grants = await _watch.grants();
    // Read once: re-sorting as the user ticks would move rows under them.
    final apps = _apps.isEmpty ? await _watch.apps() : _apps;
    if (_disposed) return;
    _grants = grants;
    _apps = apps;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycle.dispose();
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
