import 'dart:io';

import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
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
}
