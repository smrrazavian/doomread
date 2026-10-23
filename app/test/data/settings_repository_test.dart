import 'dart:io';

import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remembers the chosen language after the app restarts', () async {
    final dir = await Directory.systemTemp.createTemp('doomread');
    final file = File('${dir.path}/db.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await SettingsRepository(first).setLocale(const Locale('fa'));
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    expect(await SettingsRepository(second).locale(), const Locale('fa'));
    await second.close();
  });

  test('has no saved language on a fresh install', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await SettingsRepository(db).locale(), isNull);
    await db.close();
  });

  test('runs the vendored SQLite, compiled from source', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final row = await db
        .customSelect('select sqlite_version() as v')
        .getSingle();
    expect(row.read<String>('v'), '3.54.1');
    await db.close();
  });
}
