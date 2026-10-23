import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 30, 21);

  /// A stopped Session starting at [start] with one Stretch of [minutes].
  Session sitting(DateTime start, int minutes, {bool stopped = true}) =>
      Session.fromEvents([
        SessionEvent(SessionEventKind.start, start),
        if (stopped)
          SessionEvent(
            SessionEventKind.stop,
            start.add(Duration(minutes: minutes)),
          ),
      ], now: now);
  DateTime oct(int day, [int hour = 21]) => DateTime(2026, 10, day, hour);
  List<(int, int)> view(List<StretchRise> t) => [
    for (final r in t) (r.evening.day, r.longest.inMinutes),
  ];

  test('no Sessions, no trend', () {
    expect(longestStretchTrend(const []), isEmpty);
  });

  test('one entry per evening the Longest stretch grew', () {
    final sessions = [
      sitting(oct(9), 5),
      sitting(oct(10), 4),
      sitting(oct(12), 7),
      sitting(oct(15), 7),
      sitting(oct(20), 12),
    ];
    expect(view(longestStretchTrend(sessions)), [(9, 5), (12, 7), (20, 12)]);
  });

  test('the last entry is the Longest stretch now', () {
    final sessions = [sitting(oct(9), 5), sitting(oct(12), 9)];
    expect(
      longestStretchTrend(sessions).last.longest,
      longestStretch(sessions),
    );
  });

  test('Sessions are taken in time order, whatever order they come in', () {
    final sessions = [sitting(oct(12), 9), sitting(oct(9), 5)];
    expect(view(longestStretchTrend(sessions)), [(9, 5), (12, 9)]);
  });

  test('two rises on one evening are one entry, with the higher one', () {
    final sessions = [
      sitting(oct(9), 5),
      sitting(oct(12, 20), 7),
      sitting(oct(12, 22), 9),
    ];
    expect(view(longestStretchTrend(sessions)), [(9, 5), (12, 9)]);
  });

  test('a Session past midnight belongs to the evening before', () {
    final sessions = [sitting(oct(9), 5), sitting(oct(13, 1), 8)];
    expect(view(longestStretchTrend(sessions)), [(9, 5), (12, 8)]);
  });

  test('a Session left open does not count', () {
    final sessions = [sitting(oct(9), 5), sitting(oct(12), 0, stopped: false)];
    expect(view(longestStretchTrend(sessions)), [(9, 5)]);
  });

  test('a Session with no time in it is no rise', () {
    expect(longestStretchTrend([sitting(oct(9), 0)]), isEmpty);
  });
}
