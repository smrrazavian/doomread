import 'package:doomread/data/services/app_database.dart';
import 'package:flutter/widgets.dart';

/// The user's app-wide preferences, stored on the device.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _localeKey = 'locale';

  /// The language the user picked, or null if they never picked one.
  Future<Locale?> locale() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(_localeKey))).getSingleOrNull();
    return row == null ? null : Locale(row.value);
  }

  Future<void> setLocale(Locale locale) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _localeKey, value: locale.languageCode),
      );
}
