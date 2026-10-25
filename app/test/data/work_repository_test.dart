import 'dart:io';

import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkRepository works;

  var now = DateTime(2026, 10, 22, 21);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 22, 21);
    works = WorkRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<String> addRemains() => works.add(
    title: 'The Remains of the Day',
    author: 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: [34, 66],
  );

  group('Tasks', () {
    Future<String> addReport({DateTime? day}) => works.addTask(
      name: 'Write the Q3 report',
      day: day ?? DateTime(2026, 10, 22),
      estimate: const Duration(minutes: 45),
    );

    test('a Task keeps its name, day and estimate, and is not Done', () async {
      await addReport();
      final task = (await works.watchTasks().first).single;
      expect(task.name, 'Write the Q3 report');
      expect(task.day, DateTime(2026, 10, 22));
      expect(task.estimate, const Duration(minutes: 45));
      expect(task.done, isFalse);
    });

    test('a Task is never in the Library and never current', () async {
      final id = await addReport();
      expect(await works.watchAll().first, isEmpty);
      expect(await works.watchCurrent().first, isNull);
      await works.keepOneCurrent();
      expect(await works.watchCurrent().first, isNull);
      await works.delete(id);
      await works.restore(id);
      expect(await works.watchCurrent().first, isNull);
      expect(await works.watchTasks().first, hasLength(1));
    });

    test('a Task leaves the current Work as it is', () async {
      await addRemains();
      now = now.add(const Duration(minutes: 1));
      await addReport();
      expect(
        (await works.watchCurrent().first)!.work.title,
        'The Remains of the Day',
      );
      expect(await works.watchAll().first, hasLength(1));
    });

    test('a Task can be renamed, moved to another day and Done', () async {
      final id = await addReport();
      await works.editTask(
        id,
        name: 'Send the Q3 report',
        day: DateTime(2026, 10, 23),
      );
      now = now.add(const Duration(minutes: 52));
      await works.setDone(id);
      var task = (await works.watchTasks().first).single;
      expect(task.name, 'Send the Q3 report');
      expect(task.day, DateTime(2026, 10, 23));
      expect(task.estimate, isNull);
      expect(task.doneAt, now);

      await works.setDone(id, done: false);
      task = (await works.watchTasks().first).single;
      expect(task.done, isFalse);
    });

    test('Tasks list in the order they were added', () async {
      await works.addTask(name: 'one');
      await works.addTask(name: 'two');
      await works.addTask(name: 'three');
      expect((await works.watchTasks().first).map((t) => t.name), [
        'one',
        'two',
        'three',
      ]);
    });
  });

  test('an added Work shows up in the list', () async {
    await addRemains();
    final all = await works.watchAll().first;
    expect(all.single.title, 'The Remains of the Day');
    expect(all.single.checkpoints, [34, 66]);
  });

  test('the first Work added becomes the current one, at page 0', () async {
    await addRemains();
    final road = await works.watchCurrent().first;
    expect(road!.work.title, 'The Remains of the Day');
    expect(road.position, 0);
  });

  test('there is no current Work before any is added', () async {
    expect(await works.watchCurrent().first, isNull);
  });

  test('editing a Work keeps its id and changes its details', () async {
    final id = await addRemains();
    await works.edit(
      id,
      title: 'The Remains of the Day',
      author: 'K. Ishiguro',
      totalPages: 258,
      checkpoints: [34, 66, 98],
    );
    final work = (await works.watchAll().first).single;
    expect(work.id, id);
    expect(work.author, 'K. Ishiguro');
    expect(work.totalPages, 258);
    expect(work.checkpoints, [34, 66, 98]);
  });

  test('a Work keeps how many of its Checkpoints are estimates', () async {
    final id = await works.add(
      title: 'Dune',
      author: '',
      totalPages: 400,
      checkpoints: [100, 200, 300],
      estimated: 3,
    );
    expect((await works.watchAll().first).single.estimated, 3);
    await works.edit(
      id,
      title: 'Dune',
      author: '',
      totalPages: 400,
      checkpoints: [100, 200, 300],
    );
    expect(
      (await works.watchAll().first).single.estimated,
      0,
      reason: 'a typed list is all known',
    );
  });

  test('adding and editing stamp updatedAt with the injected clock', () async {
    final id = await addRemains();
    Future<DateTime> updatedAt() async => (await (db.select(
      db.works,
    )..where((w) => w.id.equals(id))).getSingle()).updatedAt;
    expect(await updatedAt(), DateTime(2026, 10, 22, 21));

    now = DateTime(2026, 10, 23, 8);
    await works.edit(
      id,
      title: 'The Remains of the Day',
      author: 'Kazuo Ishiguro',
      totalPages: 245,
      checkpoints: const [],
    );
    expect(await updatedAt(), DateTime(2026, 10, 23, 8));
  });

  test('picking another Work makes it current', () async {
    await addRemains();
    final dune = await works.add(
      title: 'Dune',
      author: 'Frank Herbert',
      totalPages: 412,
      checkpoints: const [],
    );
    await works.setCurrent(dune);
    expect((await works.watchCurrent().first)!.work.title, 'Dune');
  });

  group('deleting a Work', () {
    Future<String> addDune() => works.add(
      title: 'Dune',
      author: 'Frank Herbert',
      totalPages: 412,
      checkpoints: const [],
    );

    test('takes it off the list', () async {
      final id = await addRemains();
      await addDune();
      await works.delete(id);
      final all = await works.watchAll().first;
      expect(all.map((w) => w.title), ['Dune']);
    });

    test('of the current Work makes the latest other one current', () async {
      final remains = await addRemains();
      now = now.add(const Duration(minutes: 1));
      await addDune();
      await works.delete(remains);
      expect((await works.watchCurrent().first)!.work.title, 'Dune');
    });

    test('of the last Work leaves none current, until one is added', () async {
      await works.delete(await addRemains());
      expect(await works.watchCurrent().first, isNull);
      await addDune();
      expect((await works.watchCurrent().first)!.work.title, 'Dune');
    });

    test('can be undone', () async {
      final id = await addRemains();
      await works.delete(id);
      await works.restore(id);
      expect((await works.watchAll().first).single.id, id);
      expect((await works.watchCurrent().first)!.work.id, id);
    });

    test('undone, the current Work is current again', () async {
      final remains = await addRemains();
      await addDune();
      await works.delete(remains);
      await works.restore(remains, current: true);
      expect((await works.watchCurrent().first)!.work.id, remains);
    });

    test('stamps updatedAt, so sync sends it', () async {
      final id = await addRemains();
      now = DateTime(2026, 10, 23, 8);
      await works.delete(id);
      final row = await (db.select(
        db.works,
      )..where((w) => w.id.equals(id))).getSingle();
      expect(row.updatedAt, DateTime(2026, 10, 23, 8));
    });
  });

  test('the current Work survives the app restarting', () async {
    final dir = await Directory.systemTemp.createTemp('doomread');
    final file = File('${dir.path}/db.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    await WorkRepository(first).add(
      title: 'Dune',
      author: 'Frank Herbert',
      totalPages: 412,
      checkpoints: const [],
    );
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    final road = await WorkRepository(second).watchCurrent().first;
    expect(road!.work.title, 'Dune');
    await second.close();
  });

  test(
    'a series keeps its kind, and its episodes are its Checkpoints',
    () async {
      await works.add(
        title: 'Dark',
        author: 'Baran bo Odar',
        totalPages: 10,
        checkpoints: const [],
        kind: WorkKind.series,
      );
      final dark = (await works.watchAll().first).single;
      expect(dark.kind, WorkKind.series);
      expect(dark.checkpoints, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    },
  );

  test('a podcast keeps its timestamps in seconds', () async {
    await works.add(
      title: 'Lex Fridman #400',
      author: '',
      totalPages: 9660,
      checkpoints: const [2550, 4340],
      kind: WorkKind.podcast,
    );
    final podcast = (await works.watchAll().first).single;
    expect(podcast.kind, WorkKind.podcast);
    expect(podcast.checkpoints, [2550, 4340]);
  });

  test('Works saved before kinds existed open as paper books', () async {
    // The database as schema 3 left it, with one book at page 142.
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE works (id TEXT NOT NULL, title TEXT NOT NULL, '
            'author TEXT NOT NULL, total_pages INTEGER NOT NULL, '
            'checkpoints TEXT NOT NULL, '
            'position INTEGER NOT NULL DEFAULT 0, '
            'updated_at INTEGER NOT NULL, PRIMARY KEY (id))',
          )
          ..execute(
            "INSERT INTO works VALUES ('w1', 'Dune', 'Frank Herbert', 412, "
            "'100,200', 142, 0)",
          )
          ..execute(
            'CREATE TABLE session_events (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL, work_id TEXT NOT NULL, '
            'kind TEXT NOT NULL, at INTEGER NOT NULL)',
          )
          ..execute(
            'CREATE TABLE notes (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL UNIQUE, work_id TEXT NOT NULL, '
            'from_page INTEGER NOT NULL, to_page INTEGER NOT NULL, '
            'body TEXT NOT NULL, updated_at INTEGER NOT NULL)',
          )
          ..execute('PRAGMA user_version = 3'),
      ),
    );
    addTearDown(old.close);
    final road = await WorkRepository(old).watchRoad('w1').first;
    expect(road!.work.kind, WorkKind.paperBook);
    expect(road.work.totalPages, 412);
    expect(road.work.checkpoints, [100, 200]);
    expect(road.position, 142);
  });

  test('Works synced under schema 4 open as paper books too', () async {
    final old = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw
          ..execute(
            'CREATE TABLE works (id TEXT NOT NULL, title TEXT NOT NULL, '
            'author TEXT NOT NULL, total_pages INTEGER NOT NULL, '
            'checkpoints TEXT NOT NULL, '
            'position INTEGER NOT NULL DEFAULT 0, '
            'updated_at INTEGER NOT NULL, synced_at INTEGER NULL, '
            'PRIMARY KEY (id))',
          )
          // Schema 3 added the journal, so later migrations change it too.
          ..execute(
            'CREATE TABLE session_events (id TEXT NOT NULL PRIMARY KEY, '
            'session_id TEXT NOT NULL, work_id TEXT NOT NULL, '
            'kind TEXT NOT NULL, at INTEGER NOT NULL, '
            'synced INTEGER NOT NULL DEFAULT 0)',
          )
          ..execute(
            "INSERT INTO works VALUES ('w1', 'Dune', 'Frank Herbert', 412, "
            "'100,200', 142, 0, 0)",
          )
          ..execute('PRAGMA user_version = 4'),
      ),
    );
    addTearDown(old.close);
    final road = await WorkRepository(old).watchRoad('w1').first;
    expect(road!.work.kind, WorkKind.paperBook);
    expect(road.position, 142);
  });
}
