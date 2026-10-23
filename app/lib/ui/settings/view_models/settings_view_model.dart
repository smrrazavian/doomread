import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._settings);

  final SettingsRepository _settings;

  /// English until the user picks otherwise.
  Locale locale = const Locale('en');

  /// The Watched apps the user picked.
  Set<String> watched = defaultWatched;

  /// [watched] as the rules core classifies apps by.
  WatchRules get watchRules => WatchRules(watched: watched);

  /// Whether [load] has finished.
  bool loaded = false;

  Future<void> load() async {
    locale = await _settings.locale() ?? locale;
    watched = await _settings.watchedApps();
    loaded = true;
    notifyListeners();
  }

  Future<void> setWatched(String package, {required bool on}) async {
    watched = on ? {...watched, package} : ({...watched}..remove(package));
    notifyListeners();
    await _settings.setWatchedApps(watched);
  }

  Future<void> setLocale(Locale value) async {
    locale = value;
    notifyListeners();
    await _settings.setLocale(value);
  }
}
