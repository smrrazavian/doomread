import 'package:doomread/data/services/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a v5 database stamps each Position as moved at its last write',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) => raw
            ..execute(
              'CREATE TABLE settings (key TEXT NOT NULL PRIMARY KEY, '
              'value TEXT NOT NULL)',
            )
            ..execute(
              'CREATE TABLE works (id TEXT NOT NULL PRIMARY KEY, '
              'title TEXT NOT NULL, author TEXT NOT NULL, '
              "kind TEXT NOT NULL DEFAULT 'paperBook', "
              'total_pages INTEGER NOT NULL, checkpoints TEXT NOT NULL, '
              'position INTEGER NOT NULL DEFAULT 0, '
              'updated_at INTEGER NOT NULL, synced_at INTEGER NULL)',
            )
            ..execute(
              'CREATE TABLE session_events (id TEXT NOT NULL PRIMARY KEY, '
              'session_id TEXT NOT NULL, work_id TEXT NOT NULL, '
              'kind TEXT NOT NULL, at INTEGER NOT NULL, '
              'synced INTEGER NOT NULL DEFAULT 0)',
            )
            ..execute(
              'CREATE TABLE notes (id TEXT NOT NULL PRIMARY KEY, '
              'session_id TEXT NOT NULL UNIQUE, work_id TEXT NOT NULL, '
              'from_page INTEGER NOT NULL, to_page INTEGER NOT NULL, '
              'body TEXT NOT NULL, updated_at INTEGER NOT NULL, '
              'synced_at INTEGER NULL)',
            )
            ..execute(
              "INSERT INTO works VALUES ('w1', 'Dune', 'Frank Herbert', "
              "'paperBook', 412, '40,80', 150, 1761150000, 1761150000)",
            )
            ..execute('PRAGMA user_version = 5'),
        ),
      );
      addTearDown(db.close);

      final work = await db.select(db.works).getSingle();
      expect(work.position, 150);
      expect(work.positionAt, work.updatedAt);
      // Already synced, and the migration alone gives it nothing new to send.
      expect(work.syncedAt, work.updatedAt);
    },
  );

  test('a v7 journal gains a page on each event, empty for old ones', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE settings (key TEXT NOT NULL PRIMARY KEY, '
            'value TEXT NOT NULL)',
          )
          ..execute(
            'CREATE TABLE works (id TEXT NOT NULL PRIMARY KEY, '
            'title TEXT NOT NULL, author TEXT NOT NULL, '
            "kind TEXT NOT NULL DEFAULT 'paperBook', "
            'total_pages INTEGER NOT NULL, checkpoints TEXT NOT NULL, '
            'position INTEGER NOT NULL DEFAULT 0, '
            'updated_at INTEGER NOT NULL, position_at INTEGER NULL, '
            'deleted INTEGER NOT NULL DEFAULT 0, '
            'deleted_changed_at INTEGER NULL, synced_at INTEGER NULL)',
          )
          ..execute(
            'CREATE TABLE session_events (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL, work_id TEXT NOT NULL, '
            'kind TEXT NOT NULL, at INTEGER NOT NULL, '
            'synced INTEGER NOT NULL DEFAULT 0)',
          )
          ..execute(
            'CREATE TABLE notes (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL UNIQUE, work_id TEXT NOT NULL, '
            'from_page INTEGER NOT NULL, to_page INTEGER NOT NULL, '
            'body TEXT NOT NULL, updated_at INTEGER NOT NULL, '
            'synced_at INTEGER NULL)',
          )
          ..execute(
            "INSERT INTO session_events VALUES ('e1', 's1', 'w1', 'start', "
            '1761150000, 1)',
          )
          ..execute('PRAGMA user_version = 7'),
      ),
    );
    addTearDown(db.close);

    final event = await db.select(db.sessionEvents).getSingle();
    expect(event.page, isNull);
    expect(event.synced, isTrue);
  });
}
