import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:flutter/widgets.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel(this._settings);

  final SettingsRepository _settings;

  /// English until the user picks otherwise.
  Locale locale = const Locale('en');

  Future<void> load() async {
    locale = await _settings.locale() ?? locale;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    locale = value;
    notifyListeners();
    await _settings.setLocale(value);
  }
}
