import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkRepository works;
  late SessionRepository sessions;
  late StopDeletedSessionsUseCase stop;
  var now = DateTime(2026, 10, 22, 21);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 22, 21);
    works = WorkRepository(db, clock: () => now);
    sessions = SessionRepository(db, clock: () => now);
    stop = StopDeletedSessionsUseCase(works, sessions);
  });
  tearDown(() => db.close());

  Future<String> addDune() => works.add(
    title: 'Dune',
    author: 'Frank Herbert',
    totalPages: 412,
    checkpoints: const [],
  );

  Future<bool> stopped() async => (await sessions.all()).single.at(now).stopped;

  test('a Session on a Work just deleted runs on, ready for Undo', () async {
    final id = await addDune();
    await sessions.start(id);
    await works.delete(id);
    await stop();
    expect(await stopped(), isFalse);
  });

  test('once Undo is gone, the Session is stopped', () async {
    final id = await addDune();
    await sessions.start(id);
    await works.delete(id);
    await stop(settled: id);
    expect(await stopped(), isTrue);
  });

  test('a delete older than the Undo window is settled', () async {
    final id = await addDune();
    await sessions.start(id);
    await works.delete(id);
    now = now.add(StopDeletedSessionsUseCase.undoWindow);
    await stop();
    expect(await stopped(), isTrue);
  });

  test('a Session on a Work still there runs on', () async {
    await sessions.start(await addDune());
    now = now.add(const Duration(hours: 1));
    await stop();
    expect(await stopped(), isFalse);
  });
}
