import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:flutter/widgets.dart';

/// Whether the first-run intro is due: never seen, and no Work yet. Someone
/// who already has Works (an upgrade from before the intro) is marked as
/// having seen it and every hint, so they never get the tour, and keeps
/// English, which they had before languages followed the phone.
class FirstRunUseCase {
  FirstRunUseCase(this._settings, this._works);

  final SettingsRepository _settings;
  final WorkRepository _works;

  Future<bool> call() async {
    if (await _settings.introSeen()) return false;
    if (!await _works.any()) return true;
    await _settings.setIntroSeen();
    await _settings.setHintsSeen(Hint.values.toSet());
    if (await _settings.locale() == null) {
      await _settings.setLocale(const Locale('en'));
    }
    return false;
  }
}
