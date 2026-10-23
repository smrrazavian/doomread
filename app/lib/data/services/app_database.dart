import 'dart:math';

import 'package:doomread_core/doomread_core.dart';
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

/// Works the user is getting through. Checkpoints are page numbers, stored as
/// comma-separated text since they're only ever read and written whole.
@DataClassName('WorkRow')
class Works extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text()();
  IntColumn get totalPages => integer()();
  TextColumn get checkpoints => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The Session journal. Rows are only ever inserted, never changed or
/// deleted; Stretches and everything else are derived from them in `core`.
@DataClassName('SessionEventRow')
class SessionEvents extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get workId => text()();
  TextColumn get kind => textEnum<SessionEventKind>()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// How a Session ended: the page range it covered and the Note about it.
/// The text is empty when the user wrote no Note.
@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().unique()();
  TextColumn get workId => text()();
  IntColumn get fromPage => integer()();
  IntColumn get toPage => integer()();
  TextColumn get body => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Settings, Works, SessionEvents, Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database.
  AppDatabase.open() : super(driftDatabase(name: 'doomread'));

  /// The value stored under [key] in Settings, or null.
  Future<String?> setting(String key) async => (await (select(
    settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(works);
      if (from < 3) {
        await m.createTable(sessionEvents);
        await m.createTable(notes);
      }
    },
  );
}

/// A random 128-bit id, so rows can sync across devices later (ticket #16).
String newId() {
  final r = Random.secure();
  return List.generate(
    16,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
