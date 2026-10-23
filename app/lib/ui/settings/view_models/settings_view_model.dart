import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._settings);

  final SettingsRepository _settings;

  /// English until the user picks otherwise.
  Locale locale = const Locale('en');

  /// The Watched apps the user picked.
  Set<String> watched = defaultWatched;

  /// The voice the app speaks in.
  Tone tone = Tone.byDefault;

  /// Each Work's Work app, by Work id.
  Map<String, LaunchableApp> workApps = const {};

  /// The rules core classifies apps by during a Session with [workId].
  WatchRules watchRules(String workId) =>
      WatchRules(watched: watched, workApp: workApps[workId]?.package);

  /// Whether [load] has finished.
  bool loaded = false;

  Future<void> load() async {
    locale = await _settings.locale() ?? locale;
    watched = await _settings.watchedApps();
    workApps = await _settings.workApps();
    tone = await _settings.tone();
    loaded = true;
    notifyListeners();
  }

  Future<void> setWatched(String package, {required bool on}) async {
    watched = on ? {...watched, package} : ({...watched}..remove(package));
    notifyListeners();
    await _settings.setWatchedApps(watched);
  }

  /// Sets the app that holds [workId], or none when it isn't on the phone.
  Future<void> setWorkApp(String workId, LaunchableApp? app) async {
    workApps = {...workApps}..remove(workId);
    if (app != null) workApps[workId] = app;
    notifyListeners();
    await _settings.setWorkApps(workApps);
  }

  Future<void> setTone(Tone value) async {
    tone = value;
    notifyListeners();
    await _settings.setTone(value);
  }

  Future<void> setLocale(Locale value) async {
    locale = value;
    notifyListeners();
    await _settings.setLocale(value);
  }
}
