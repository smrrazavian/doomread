import 'dart:convert';

import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/data/services/app_watch.dart';
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
  static const _workAppsKey = 'workApps';

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

  /// Each Work's Work app, by Work id. Kept on this device: package names
  /// belong to it, like the current Work (ADR 0012).
  Future<Map<String, LaunchableApp>> workApps() async {
    final v = await _db.setting(_workAppsKey);
    if (v == null) return const {};
    return {
      for (final MapEntry(:key, :value)
          in (jsonDecode(v) as Map<String, Object?>).entries)
        if (value case {'package': final String p, 'label': final String l})
          key: (package: p, label: l),
    };
  }

  Future<void> setWorkApps(Map<String, LaunchableApp> apps) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(
          key: _workAppsKey,
          value: jsonEncode({
            for (final MapEntry(:key, :value) in apps.entries)
              key: {'package': value.package, 'label': value.label},
          }),
        ),
      );
}
