import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/drift.dart' show Value;

/// The Remains of the Day at page 128, read to 142 last night in 14 minutes
/// in one go: a page a minute, and a 12-minute interval tonight.
// The records are built by hand: watching the journal before the app is
// pumped would wait on drift timers that fake time never fires.
Future<void> addRemainsReadLastNight(
  AppDatabase db,
  String lang,
  void Function(DateTime) setNow,
) async {
  final id = await WorkRepository(db).add(
    title: lang == 'fa' ? 'بازمانده‌ی روز' : 'The Remains of the Day',
    author: lang == 'fa' ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: [34, 66, 98, 128, 156, 194, 222],
  );
  await (db.update(db.works)..where((w) => w.id.equals(id))).write(
    const WorksCompanion(position: Value(128)),
  );
  var now = DateTime(2026, 10, 21, 21);
  setNow(now);
  final sessions = SessionRepository(db, clock: () => now);
  final work = Work(
    id: id,
    title: '',
    author: '',
    totalPages: 245,
    checkpoints: const [],
  );
  final record = SessionRecord(
    id: await sessions.start(id),
    road: Road(work, position: 0),
    events: const [],
  );
  now = now.add(const Duration(minutes: 14));
  setNow(now);
  await sessions.add(record, SessionEventKind.stop);
  await sessions.end(record, page: 142);
  setNow(DateTime(2026, 10, 22, 21));
}

/// Dark, season 1, at episode 3, after watching episode 3 last night in 14
/// minutes in one go: an episode every 14 minutes, so tonight's break is at
/// the end of episode 4.
Future<void> addDarkWatchedLastNight(
  AppDatabase db,
  String lang,
  void Function(DateTime) setNow,
) async {
  final id = await WorkRepository(db).add(
    title: lang == 'fa' ? 'دارک، فصل ۱' : 'Dark, season 1',
    author: lang == 'fa' ? 'باران بو اودار' : 'Baran bo Odar',
    totalPages: 10,
    checkpoints: const [],
    kind: WorkKind.series,
  );
  await (db.update(db.works)..where((w) => w.id.equals(id))).write(
    const WorksCompanion(position: Value(2)),
  );
  var now = DateTime(2026, 10, 21, 21);
  setNow(now);
  final sessions = SessionRepository(db, clock: () => now);
  final record = SessionRecord(
    id: await sessions.start(id),
    road: Road(
      Work(id: id, title: '', author: '', totalPages: 10, checkpoints: []),
      position: 0,
    ),
    events: const [],
  );
  now = now.add(const Duration(minutes: 14));
  setNow(now);
  await sessions.add(record, SessionEventKind.stop);
  await sessions.end(record, page: 3);
  setNow(DateTime(2026, 10, 22, 21));
}
