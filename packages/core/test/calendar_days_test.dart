import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // Thursday 22 October 2026, 21:00.
  final now = DateTime(2026, 10, 22, 21);
  final october = [for (var d = 1; d <= 31; d++) DateTime(2026, 10, d)];

  /// A stopped Session from [start], [minutes] long.
  Session sat(DateTime start, int minutes) => Session.fromEvents([
    SessionEvent(SessionEventKind.start, start),
    SessionEvent(SessionEventKind.stop, start.add(Duration(minutes: minutes))),
  ], now: now);

  Map<DateTime, CalendarDay> days({
    List<Session> sessions = const [],
    List<Task> tasks = const [],
    List<DateTime> finishes = const [],
  }) => calendarDays(
    october,
    now: now,
    sessions: sessions,
    tasks: tasks,
    finishes: finishes,
  );

  test('focus adds up every stopped Session of the day, of any kind', () {
    final d = days(
      sessions: [
        sat(DateTime(2026, 10, 3, 9), 50),
        sat(DateTime(2026, 10, 3, 21), 40),
        // Left open: it lights nothing up by itself.
        Session.fromEvents([
          SessionEvent(SessionEventKind.start, DateTime(2026, 10, 3, 23)),
        ], now: now),
      ],
    );
    expect(d[DateTime(2026, 10, 3)]!.focus, const Duration(minutes: 90));
  });

  test('days turn over at 4 in the morning', () {
    final d = days(
      sessions: [
        sat(DateTime(2026, 10, 4, 3, 59), 10),
        sat(DateTime(2026, 10, 4, 4), 20),
      ],
      tasks: [
        Task(id: 't', name: 'Call the bank', doneAt: DateTime(2026, 10, 9, 1)),
      ],
      finishes: [DateTime(2026, 10, 12, 2)],
    );
    expect(d[DateTime(2026, 10, 3)]!.focus, const Duration(minutes: 10));
    expect(d[DateTime(2026, 10, 4)]!.focus, const Duration(minutes: 20));
    expect(d[DateTime(2026, 10, 8)]!.tasksDone, 1);
    expect(d[DateTime(2026, 10, 9)]!.tasksDone, 0);
    expect(d[DateTime(2026, 10, 11)]!.finishes, 1);
  });

  test('planned Tasks show only on days still to come', () {
    final d = days(
      tasks: [
        Task(id: 'a', name: 'Dentist', day: DateTime(2026, 10, 25)),
        Task(id: 'b', name: 'Dentist again', day: DateTime(2026, 10, 25)),
        // Undone from an earlier day: it carries over, unmarked.
        Task(id: 'c', name: 'Old one', day: DateTime(2026, 10, 10)),
        // Done ahead of its day: it counts where it was Done.
        Task(
          id: 'd',
          name: 'Early',
          day: DateTime(2026, 10, 28),
          doneAt: DateTime(2026, 10, 22, 10),
        ),
      ],
    );
    expect(d[DateTime(2026, 10, 25)]!.planned, 2);
    expect(d[DateTime(2026, 10, 10)]!.planned, 0);
    expect(d[DateTime(2026, 10, 28)]!.planned, 0);
    expect(d[DateTime(2026, 10, 22)]!.tasksDone, 1);
  });

  test('a dark day holds nothing at all', () {
    final d = days(sessions: [sat(DateTime(2026, 10, 3, 21), 20)]);
    expect(d[DateTime(2026, 10, 5)], (
      focus: Duration.zero,
      tasksDone: 0,
      planned: 0,
      finishes: 0,
    ));
    expect(d, hasLength(31));
  });

  test('days outside the ones asked for are left out', () {
    final d = days(sessions: [sat(DateTime(2026, 9, 30, 21), 20)]);
    expect(d.containsKey(DateTime(2026, 9, 30)), isFalse);
    expect(d.values.every((day) => day.focus == Duration.zero), isTrue);
  });
}
