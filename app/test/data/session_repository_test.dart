import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late String workId;
  var now = DateTime(2026, 10, 22, 21);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 22, 21);
    sessions = SessionRepository(db, clock: () => now);
    workId = await WorkRepository(db).add(
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    await (db.update(db.works)..where((w) => w.id.equals(workId))).write(
      const WorksCompanion(position: Value(142)),
    );
  });
  tearDown(() => db.close());

  Future<SessionRecord> only() async =>
      (await sessions.watchAll().first).single;

  test('each action is a timestamped event in the journal', () async {
    final id = await sessions.start(workId);
    now = now.add(const Duration(minutes: 5));
    await sessions.add(await only(), SessionEventKind.pause);
    now = now.add(const Duration(minutes: 1));
    await sessions.add(await only(), SessionEventKind.resume);
    now = now.add(const Duration(minutes: 3));
    await sessions.add(await only(), SessionEventKind.stop);

    final record = await only();
    expect(record.id, id);
    expect(record.road.work.id, workId);
    expect(record.events.map((e) => e.kind), [
      SessionEventKind.start,
      SessionEventKind.pause,
      SessionEventKind.resume,
      SessionEventKind.stop,
    ]);
    expect(record.events.first.at, DateTime(2026, 10, 22, 21));
    final session = record.at(now);
    expect(session.stretches.map((s) => s.length.inMinutes), [5, 3]);
    expect(session.stopped, isTrue);
  });

  test('events in the same second keep the order they were added', () async {
    await sessions.start(workId);
    await sessions.add(await only(), SessionEventKind.pause);
    await sessions.add(await only(), SessionEventKind.resume);
    final record = await only();
    expect(record.events.last.kind, SessionEventKind.resume);
    expect(record.at(now).paused, isFalse);
  });

  test('ending moves the Position and saves the Note on that range', () async {
    await sessions.start(workId);
    await sessions.add(await only(), SessionEventKind.stop);
    await sessions.end(
      await only(),
      page: 156,
      note: ' Stevens misses Miss Kenton, only to himself. ',
    );

    final record = await only();
    expect(record.road.position, 156);
    expect(record.pages, (from: 142, to: 156));
    final note = await db.select(db.notes).getSingle();
    expect(note.body, 'Stevens misses Miss Kenton, only to himself.');
    expect((await WorkRepository(db).watchCurrent().first)!.position, 156);
  });

  test('a v2 install gains the journal and keeps its Works', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE settings (key TEXT NOT NULL PRIMARY KEY, '
            'value TEXT NOT NULL)',
          )
          ..execute(
            'CREATE TABLE works (id TEXT NOT NULL PRIMARY KEY, '
            'title TEXT NOT NULL, author TEXT NOT NULL, '
            'total_pages INTEGER NOT NULL, checkpoints TEXT NOT NULL, '
            'position INTEGER NOT NULL DEFAULT 0, '
            'updated_at INTEGER NOT NULL)',
          )
          ..execute(
            "INSERT INTO works VALUES ('w1', 'Dune', 'Frank Herbert', "
            "412, '', 30, 0)",
          )
          ..execute('PRAGMA user_version = 2'),
      ),
    );
    addTearDown(old.close);
    final journal = SessionRepository(old, clock: () => now);
    await journal.start('w1');
    final record = (await journal.watchAll().first).single;
    expect(record.road.work.title, 'Dune');
    expect(record.road.position, 30);
  });

  test('Sessions are kept apart and listed oldest first', () async {
    final first = await sessions.start(workId);
    now = now.add(const Duration(hours: 1));
    final second = await sessions.start(workId);
    final all = await sessions.watchAll().first;
    expect(all.map((r) => r.id), [first, second]);
    expect(all.every((r) => r.events.length == 1), isTrue);
  });

  test('reading and watching keep their Longest stretch apart', () async {
    final dark = await WorkRepository(db).add(
      title: 'Dark',
      author: '',
      totalPages: 10,
      checkpoints: const [],
      kind: WorkKind.series,
    );
    Future<void> sit(String work, Duration length) async {
      await sessions.start(work);
      now = now.add(length);
      final open = (await sessions.watchAll().first).last;
      await sessions.add(open, SessionEventKind.stop);
    }

    await sit(workId, const Duration(minutes: 6));
    await sit(dark, const Duration(minutes: 40));
    final all = await sessions.watchAll().first;
    Duration longest(WorkKind kind) =>
        longestStretch(alike(all, kind).map((r) => r.at(now)));
    expect(longest(WorkKind.ebook), const Duration(minutes: 6));
    expect(longest(WorkKind.podcast), const Duration(minutes: 40));
  });
}
