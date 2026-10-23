import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

/// The user's app-wide preferences, stored on the device.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _localeKey = 'locale';
  static const _notificationsAskedKey = 'notificationsAsked';
  static const _watchedKey = 'watchedApps';
  static const _watchAskedKey = 'watchAsked';

  /// The language the user picked, or null if they never picked one.
  Future<Locale?> locale() async {
    final code = await _db.setting(_localeKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale locale) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _localeKey, value: locale.languageCode),
      );

  /// Whether the user was already asked about the Session notification, so
  /// they are asked once, whatever they answered.
  Future<bool> notificationsAsked() async =>
      await _db.setting(_notificationsAskedKey) != null;

  Future<void> setNotificationsAsked() => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _notificationsAskedKey, value: '1'),
      );

  /// The Watched apps' packages; Instagram and TikTok until the user picks.
  Future<Set<String>> watchedApps() async {
    final v = await _db.setting(_watchedKey);
    if (v == null) return defaultWatched;
    return {...v.split(',').where((p) => p.isNotEmpty)};
  }

  Future<void> setWatchedApps(Set<String> packages) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _watchedKey, value: packages.join(',')),
      );

  /// Whether the Watched apps disclosure was offered at a Start, so it's
  /// offered there once, whatever the answer.
  Future<bool> watchAsked() async => await _db.setting(_watchAskedKey) != null;

  Future<void> setWatchAsked() => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: _watchAskedKey, value: '1'),
      );
}
