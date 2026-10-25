import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  /// A stopped Session from [start], [minutes] long.
  Session sat(DateTime start, int minutes) => Session.fromEvents([
    SessionEvent(SessionEventKind.start, start),
    SessionEvent(SessionEventKind.stop, start.add(Duration(minutes: minutes))),
  ], now: DateTime(2027));

  ReadingMonth month(
    DateTime now, {
    bool solarHijri = false,
    List<Session> sessions = const [],
  }) => ReadingMonth(now: now, solarHijri: solarHijri, sessions: sessions);

  test('in English it is the Gregorian month, Monday first', () {
    final m = month(DateTime(2026, 10, 22, 21));
    expect(m.nights, hasLength(31));
    expect(m.nights.first, DateTime(2026, 10));
    expect(m.nights.last, DateTime(2026, 10, 31));
    expect(m.calendarMonth, (year: 2026, month: 10));
    // 1 October 2026 is a Thursday.
    expect(m.leadingDays(firstDayOfWeek('en')), 3);
  });

  test('in Persian it is the Solar Hijri month, Saturday first', () {
    // 1 Aban 1405 is 23 October 2026, a Friday: the week's last day.
    final m = month(DateTime(2026, 10, 24, 21), solarHijri: true);
    expect(m.calendarMonth, (year: 1405, month: 8));
    expect(m.nights, hasLength(30));
    expect(m.nights.first, DateTime(2026, 10, 23));
    expect(m.nights.last, DateTime(2026, 11, 21));
    expect(m.leadingDays(firstDayOfWeek('fa')), 6);
  });

  test('Mehr has 30 nights and Shahrivar 31', () {
    final mehr = month(DateTime(2026, 10, 22, 21), solarHijri: true);
    expect(mehr.calendarMonth, (year: 1405, month: 7));
    expect(mehr.nights, hasLength(30));
    expect(mehr.nights.last, DateTime(2026, 10, 22));
    final shahrivar = month(DateTime(2026, 9, 1, 21), solarHijri: true);
    expect(shahrivar.calendarMonth, (year: 1405, month: 6));
    expect(shahrivar.nights, hasLength(31));
  });

  test('Esfand ends the Solar Hijri year', () {
    final m = month(DateTime(2026, 3, 10, 21), solarHijri: true);
    expect(m.calendarMonth.month, 12);
    expect(m.nights.last.add(const Duration(days: 1)), DateTime(2026, 3, 21));
  });

  test('each lit night holds its reading; the rest stay dark', () {
    final m = month(
      DateTime(2026, 10, 22, 21),
      sessions: [
        sat(DateTime(2026, 10, 3, 21), 12),
        sat(DateTime(2026, 10, 3, 22), 9),
        sat(DateTime(2026, 10, 20, 21), 31),
        // The last night of September: not this month.
        sat(DateTime(2026, 9, 30, 23), 40),
      ],
    );
    expect(m.readingOn(DateTime(2026, 10, 3)), const Duration(minutes: 21));
    expect(m.isLit(DateTime(2026, 10, 3)), isTrue);
    expect(m.isLit(DateTime(2026, 10, 4)), isFalse);
    expect(m.readingOn(DateTime(2026, 10, 4)), Duration.zero);
    expect(m.count, 2);
    expect(m.longestNight, const Duration(minutes: 31));
  });

  test('a Session at 1 a.m. lights the evening before', () {
    final m = month(
      DateTime(2026, 11, 1, 2),
      sessions: [sat(DateTime(2026, 11, 1, 1), 20)],
    );
    expect(m.tonight, DateTime(2026, 10, 31));
    expect(m.calendarMonth.month, 10);
    expect(m.readingOn(DateTime(2026, 10, 31)), const Duration(minutes: 20));
  });

  test('a Session left open lights its night but adds no time', () {
    final open = Session.fromEvents([
      SessionEvent(SessionEventKind.start, DateTime(2026, 10, 5, 21)),
    ], now: DateTime(2026, 10, 22));
    final m = month(DateTime(2026, 10, 22, 21), sessions: [open]);
    expect(m.isLit(DateTime(2026, 10, 5)), isTrue);
    expect(m.readingOn(DateTime(2026, 10, 5)), Duration.zero);
    expect(m.longestNight, Duration.zero);
  });

  test('it can show another month, with tonight still tonight', () {
    final m = ReadingMonth(
      now: DateTime(2026, 10, 22, 21),
      solarHijri: false,
      sessions: [sat(DateTime(2026, 9, 12, 21), 15)],
      showing: DateTime(2026, 9, 30),
    );
    expect(m.calendarMonth, (year: 2026, month: 9));
    expect(m.nights, hasLength(30));
    expect(m.tonight, DateTime(2026, 10, 22));
    expect(m.isLit(DateTime(2026, 9, 12)), isTrue);
  });

  test('in Persian, the night before 1 Aban is still Mehr', () {
    DateTime d(int day) => DateTime(2026, 10, day);
    final now = DateTime(2026, 10, 22, 21);
    ReadingMonth at(DateTime showing) => ReadingMonth(
      now: now,
      solarHijri: true,
      sessions: const [],
      showing: showing,
    );
    expect(at(d(22)).calendarMonth, (year: 1405, month: 7));
    expect(at(d(23)).calendarMonth, (year: 1405, month: 8));
  });
}
