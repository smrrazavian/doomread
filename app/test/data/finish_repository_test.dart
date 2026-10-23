import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late WorkRepository works;
  var now = DateTime(2026, 10, 1, 21);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sessions = SessionRepository(db, clock: () => now);
    works = WorkRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<String> book(String title, int pages) => works.add(
    title: title,
    author: '',
    totalPages: pages,
    checkpoints: const [],
  );

  /// A Session at 21:00 on [day] October, [minutes] in one go, ended at
  /// [page] with [note].
  Future<void> read(
    String workId,
    int day,
    int minutes,
    int page, [
    String note = '',
  ]) async {
    now = DateTime(2026, 10, day, 21);
    final record = SessionRecord(
      id: await sessions.start(workId),
      road: Road(
        Work(
          id: workId,
          title: '',
          author: '',
          totalPages: 1,
          checkpoints: const [],
        ),
        position: 0,
      ),
      events: const [],
    );
    now = now.add(Duration(minutes: minutes));
    await sessions.add(record, SessionEventKind.stop);
    await sessions.end(record, page: page, note: note);
  }

  test('a Work is a Finish once a Session ends on its last page', () async {
    final dune = await book('Dune', 412);
    await read(dune, 2, 6, 200, 'Paul drinks the Water of Life.');
    expect(await sessions.watchFinishes().first, isEmpty);

    await read(dune, 3, 11, 412, '  ');
    final finish = (await sessions.watchFinishes().first).single;
    expect(finish.work.title, 'Dune');
    expect(finish.pages, 412);
    expect(finish.evenings, 2);
    expect(finish.longestStretch, const Duration(minutes: 11));
    expect(finish.notes, 1, reason: 'the blank Note is not counted');
    expect(finish.at, DateTime(2026, 10, 3, 21));
  });

  test('Finishes come most recent first', () async {
    final dune = await book('Dune', 100);
    final piranesi = await book('Piranesi', 100);
    final unfinished = await book('Middlemarch', 900);
    await read(piranesi, 2, 5, 100);
    await read(dune, 5, 5, 100);
    await read(unfinished, 6, 5, 300);

    final finishes = await sessions.watchFinishes().first;
    expect(finishes.map((f) => f.work.title), ['Dune', 'Piranesi']);
  });

  test("each Session carries its Note; a Work's Road can be watched", () async {
    final dune = await book('Dune', 412);
    await read(dune, 2, 6, 120, 'Arrakis at last.');

    final record = (await sessions.watchAll().first).single;
    expect(record.note, 'Arrakis at last.');
    expect(record.pages, (from: 0, to: 120));
    final road = await works.watchRoad(dune).first;
    expect(road!.position, 120);
    expect(await works.watchRoad('nope').first, isNull);
  });
}
