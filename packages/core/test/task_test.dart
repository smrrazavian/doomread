import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // Saturday 24 October 2026, mid-afternoon.
  final now = DateTime(2026, 10, 24, 14, 20);
  final today = DateTime(2026, 10, 24);

  Task task(String id, {DateTime? day, DateTime? doneAt}) =>
      Task(id: id, name: id, day: day, doneAt: doneAt);

  List<String> shown(List<Task> tasks, {DateTime? at}) => [
    for (final t in tasksToday(tasks, at ?? now)) t.id,
  ];

  test('a Task planned for today shows on Today', () {
    expect(shown([task('report', day: today)]), ['report']);
  });

  test('an undone Task from an earlier day carries over', () {
    expect(shown([task('bank', day: DateTime(2026, 10, 20))]), ['bank']);
  });

  test('a Task with no day always shows until it is done', () {
    expect(shown([task('someday')]), ['someday']);
  });

  test('a Task planned for a later day waits for it', () {
    expect(shown([task('dentist', day: DateTime(2026, 10, 25))]), isEmpty);
  });

  test('a Task done today stays, one done before today is gone', () {
    final tasks = [
      task('emails', day: today, doneAt: DateTime(2026, 10, 24, 11, 40)),
      task('old', day: today, doneAt: DateTime(2026, 10, 23, 22)),
    ];
    expect(shown(tasks), ['emails']);
  });

  test('done ones come first, then undone in the order they were added', () {
    final tasks = [
      task('report', day: today),
      task('emails', day: today, doneAt: DateTime(2026, 10, 24, 11, 40)),
      task('bank', day: DateTime(2026, 10, 20)),
    ];
    expect(shown(tasks), ['emails', 'report', 'bank']);
  });

  test('the day turns over at 4 in the morning, as evenings do', () {
    // 1am on Sunday is still Saturday: tomorrow's Task waits, and one done
    // at midnight still counts as done today.
    final late = DateTime(2026, 10, 25, 1);
    final tasks = [
      task('sunday', day: DateTime(2026, 10, 25)),
      task('midnight', day: today, doneAt: DateTime(2026, 10, 25, 0, 5)),
    ];
    expect(shown(tasks, at: late), ['midnight']);
    expect(shown(tasks, at: DateTime(2026, 10, 25, 4)), ['sunday']);
  });

  test('the next Task to start is the first undone one', () {
    final tasks = tasksToday([
      task('emails', day: today, doneAt: DateTime(2026, 10, 24, 11, 40)),
      task('report', day: today),
      task('bank', day: today),
    ], now);
    expect(nextTask(tasks)?.id, 'report');
    expect(nextTask(tasks.take(1))?.id, isNull);
  });

  test('a Task is a kind of Work that keeps out of reading and watching', () {
    expect(WorkKind.task.attention, Attention.working);
    expect(WorkKind.paperBook.attention, Attention.reading);
    expect(WorkKind.ebook.attention, Attention.reading);
    for (final k in [WorkKind.series, WorkKind.film, WorkKind.podcast]) {
      expect(k.attention, Attention.watching, reason: '$k');
    }
    expect(WorkKind.media, isNot(contains(WorkKind.task)));
    expect(WorkKind.media, hasLength(WorkKind.values.length - 1));
  });
}
