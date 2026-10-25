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

  test('a Start keeps the page it started at', () async {
    await sessions.start(workId);
    final record = await only();
    expect(record.events.single.page, 142);
    expect(record.at(now).startPage, 142);
  });

  test('a Checkpoint marked done moves the Position to it at once, and '
      'ending still counts the range from the start', () async {
    await (db.update(db.works)..where((w) => w.id.equals(workId))).write(
      const WorksCompanion(checkpoints: Value('120,150,170')),
    );
    await sessions.start(workId);
    now = now.add(const Duration(minutes: 9));
    await sessions.markCheckpoint(await only());

    var record = await only();
    expect(record.road.position, 150);
    expect(record.events.last.kind, SessionEventKind.checkpoint);
    expect(record.events.last.page, 150);
    expect(record.at(now).checkpoints.single.page, 150);

    // The next one counts on from there.
    await sessions.markCheckpoint(record);
    record = await only();
    expect(record.road.position, 170);

    await sessions.add(record, SessionEventKind.stop);
    await sessions.end(await only(), page: 172);
    expect((await only()).pages, (from: 142, to: 172));
  });

  test('a chapter marked done on an estimate keeps the real page, and '
      'the estimates after it spread on from there', () async {
    await (db.update(db.works)..where((w) => w.id.equals(workId))).write(
      const WorksCompanion(
        checkpoints: Value('100,160,220'),
        estimated: Value(2),
      ),
    );
    await sessions.start(workId);
    now = now.add(const Duration(minutes: 9));
    await sessions.markCheckpoint(await only(), page: 170);

    final record = await only();
    expect(record.road.position, 170);
    expect(record.events.last.page, 170);
    expect(record.road.work.checkpoints, [100, 170, 208]);
    expect(record.road.work.estimated, 1);
    expect(chapterEndingAt(record.road.work, 170), 2);
  });

  test('an estimate marked without a page is taken as it is', () async {
    await (db.update(db.works)..where((w) => w.id.equals(workId))).write(
      const WorksCompanion(checkpoints: Value('160,220'), estimated: Value(2)),
    );
    await sessions.start(workId);
    await sessions.markCheckpoint(await only());
    final record = await only();
    expect(record.road.position, 160);
    expect(record.road.work.checkpoints, [160, 203]);
    expect(record.road.work.estimated, 1);
  });

  test('a known Checkpoint ignores a page given with it', () async {
    await (db.update(db.works)..where((w) => w.id.equals(workId))).write(
      const WorksCompanion(checkpoints: Value('160,220')),
    );
    await sessions.start(workId);
    await sessions.markCheckpoint(await only(), page: 170);
    final record = await only();
    expect(record.road.position, 160);
    expect(record.road.work.checkpoints, [160, 220]);
  });

  test('with no Checkpoint ahead short of the end, marking does '
      'nothing', () async {
    await (db.update(db.works)..where((w) => w.id.equals(workId))).write(
      const WorksCompanion(checkpoints: Value('120,245')),
    );
    await sessions.start(workId);
    await sessions.markCheckpoint(await only());
    final record = await only();
    expect(record.events, hasLength(1));
    expect(record.road.position, 142);
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
}
