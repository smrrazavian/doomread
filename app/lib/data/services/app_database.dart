import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Small key/value settings, such as the chosen language.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database.
  AppDatabase.open() : super(driftDatabase(name: 'doomread'));

  @override
  int get schemaVersion => 1;
}
