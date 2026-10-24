import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  Duration min(num m) => Duration(seconds: (m * 60).round());

  // An evening, measured in minutes from 21:00.
  DateTime t(num m) => DateTime(2026, 10, 22, 21).add(min(m));
  SessionEvent ev(SessionEventKind k, num m) => SessionEvent(k, t(m));
  SessionEvent start(num m) => ev(SessionEventKind.start, m);
  SessionEvent pause(num m) => ev(SessionEventKind.pause, m);
  SessionEvent resume(num m) => ev(SessionEventKind.resume, m);
  SessionEvent stop(num m) => ev(SessionEventKind.stop, m);
  SessionEvent breakStart(num m) => ev(SessionEventKind.breakStart, m);
  SessionEvent breakEnd(num m) => ev(SessionEventKind.breakEnd, m);
  SessionEvent nudge(num m) => ev(SessionEventKind.nudge, m);
  SessionEvent done(num m, int page) =>
      SessionEvent(SessionEventKind.checkpoint, t(m), page: page);
  Session reduce(List<SessionEvent> events, {num now = 120}) =>
      Session.fromEvents(events, now: t(now));

  group('the interval grows with the Longest stretch', () {
    final cases = {
      Duration.zero: (12, 3),
      min(5.5): (12, 3),
      min(12): (12, 3),
      min(15.9): (12, 3),
      min(16): (16, 4),
      min(19): (16, 4),
      min(20): (20, 5),
      min(24): (24, 6),
      min(90): (24, 6),
    };
    for (final MapEntry(key: longest, value: (reading, rest))
        in cases.entries) {
      test('a Longest stretch of $longest reads $reading, rests $rest', () {
        final interval = breakInterval(longest);
        expect(interval, min(reading));
        expect(breakLength(interval), min(rest));
      });
    }
  });

  group('break length', () {
    test('is 1 minute per 4 minutes of reading, rounded up', () {
      expect(breakLength(min(12)), min(3));
      expect(breakLength(min(13)), min(4));
      expect(breakLength(min(17.3)), min(5));
    });

    test('is 10 minutes at most', () {
      expect(breakLength(min(40)), min(10));
      expect(breakLength(min(75)), min(10));
    });
  });

  group('placing a break', () {
    // 30 seconds a page: 12 minutes of reading is 24 pages.
    PlannedBreak? place({
      Duration? from,
      int fromPage = 100,
      List<int> checkpoints = const [130, 150, 170],
      Duration? perPage = const Duration(seconds: 30),
      int totalPages = 245,
    }) => placeBreak(
      interval: min(12),
      from: from ?? min(12),
      fromPage: fromPage,
      totalPages: totalPages,
      checkpoints: checkpoints,
      perPage: perPage,
    );

    test('lands at the first Checkpoint after the interval', () {
      // Page 124 after 12 minutes; the Checkpoint at 130 is 3 minutes on.
      final b = place()!;
      expect(b.checkpoint, 130);
      expect(b.from, min(12));
      expect(b.at, min(15));
      expect(b.length, min(4));
    });

    test('a Checkpoint right at the interval counts', () {
      expect(place(checkpoints: [124])!.at, min(12));
    });

    test('Checkpoints behind the interval are passed by', () {
      expect(place(checkpoints: [105, 120, 128])!.checkpoint, 128);
    });

    test('falls at the end of the page when the Checkpoint is too far', () {
      // 6 minutes on (half the interval) is still close enough; 7 is not.
      expect(place(checkpoints: [136])!.checkpoint, 136);
      final b = place(checkpoints: [138])!;
      expect(b.checkpoint, isNull);
      expect(b.at, min(12));
      expect(b.length, min(3));
    });

    test('falls at the end of the page when the Work has no Checkpoints', () {
      final b = place(checkpoints: const [])!;
      expect(b.checkpoint, isNull);
      expect(b.at, min(12));
    });

    test('falls at the end of the page with no Checkpoint ahead', () {
      expect(place(checkpoints: [50, 90])!.checkpoint, isNull);
    });

    test('without a pace, nothing is guessed: the end of the page', () {
      final b = place(perPage: null)!;
      expect(b.checkpoint, isNull);
      expect(b.at, min(12));
    });

    test('there is no break when the Finish comes first', () {
      expect(place(totalPages: 120), isNull);
      expect(place(totalPages: 124), isNull);
    });

    test('the last page is no Checkpoint to break at', () {
      expect(place(checkpoints: [130], totalPages: 130)!.checkpoint, isNull);
    });
  });

  group('the reducer', () {
    test('a Planned break ends the Stretch, and back starts a new one', () {
      final s = reduce([start(0), breakStart(15), breakEnd(19), stop(30)]);
      expect(s.stretches.map((st) => st.length), [min(15), min(11)]);
      expect(s.stretches.first.endedBy, StretchEnd.plannedBreak);
      expect(s.breaks, [(start: t(15), end: t(19))]);
    });

    test('while on a break, the Session is on a break, not paused', () {
      final s = reduce([start(0), breakStart(15)], now: 17);
      expect(s.onBreak, isTrue);
      expect(s.paused, isFalse);
      expect(s.current, isNull);
      expect(s.breaks.single.end, isNull);
    });

    test('a break can start while paused', () {
      final s = reduce([start(0), pause(10), breakStart(11)]);
      expect(s.onBreak, isTrue);
      expect(s.stretches.single.endedBy, StretchEnd.pause);
    });

    test('Resume during a break ends it; a Pause is ignored', () {
      final s = reduce([start(0), breakStart(15), pause(16), resume(18)]);
      expect(s.onBreak, isFalse);
      expect(s.breaks.single.end, t(18));
      expect(s.current!.start, t(18));
    });

    test('a second break start, or a stray break end, is ignored', () {
      final s = reduce([
        start(0),
        breakEnd(5),
        breakStart(15),
        breakStart(16),
        breakEnd(18),
        breakEnd(19),
      ]);
      expect(s.breaks, [(start: t(15), end: t(18))]);
      expect(s.current!.start, t(18));
    });

    test('Stop during a break ends the break too', () {
      final s = reduce([start(0), breakStart(15), stop(20)]);
      expect(s.stopped, isTrue);
      expect(s.onBreak, isFalse);
      expect(s.breaks.single.end, t(20));
    });

    test('nudges count only while reading or paused', () {
      final s = reduce([
        nudge(-1),
        start(0),
        nudge(12),
        pause(13),
        nudge(14),
        breakStart(20),
        nudge(21),
        breakEnd(23),
        stop(30),
        nudge(31),
      ]);
      expect(s.nudges, [t(12), t(14)]);
    });

    test('reading since the last break leaves out pauses and the break', () {
      final s = reduce([
        start(0),
        pause(5),
        resume(7),
        breakStart(15),
        breakEnd(19),
        pause(25),
        resume(26),
      ], now: 30);
      expect(s.readingSinceBreak, min(10));
      expect(
        reduce([start(0), pause(5), resume(7)], now: 10).readingSinceBreak,
        min(8),
      );
    });
  });

  group('the Planned break of a Session', () {
    // Page 100 at the Start, 20 seconds a page, a Checkpoint every 30 pages:
    // page 136 after 12 minutes, so the first break is at 145, 15 minutes in.
    PlannedBreak? breakOf(
      List<SessionEvent> events, {
      num now = 120,
      Duration longest = Duration.zero,
      Duration? perPage = const Duration(seconds: 20),
      List<int> checkpoints = const [115, 145, 175, 205, 235],
      int startPage = 100,
    }) => plannedBreak(
      reduce(events, now: now),
      longestStretch: longest,
      startPage: startPage,
      totalPages: 245,
      checkpoints: checkpoints,
      perPage: perPage,
    );

    test('the first is offered from the interval on', () {
      final b = breakOf([start(0)], now: 1)!;
      expect(b.from, min(12));
      expect(b.checkpoint, 145);
      expect(b.at, min(15));
      expect(b.length, min(4));
    });

    test('a longer Longest stretch asks for more reading first', () {
      // 24 minutes is page 172; the Checkpoint at 175 is a minute on.
      final b = breakOf([start(0)], now: 1, longest: min(30))!;
      expect(b.from, min(24));
      expect(b.checkpoint, 175);
      expect(b.length, min(7));
    });

    test('a nudge moves it to the next Checkpoint, a bigger break', () {
      final b = breakOf([start(0), nudge(14)])!;
      expect(b.checkpoint, 175);
      expect(b.at, min(25));
      expect(b.length, min(7));
    });

    test('nudged again and again, the break stops growing at 10', () {
      final b = breakOf([start(0), nudge(14), nudge(24), nudge(34)])!;
      expect(b.checkpoint, 235);
      expect(b.at, min(45));
      expect(b.length, min(10));
    });

    test('a nudge without Checkpoints moves it half an interval on', () {
      final b = breakOf([start(0), nudge(12)], checkpoints: const [])!;
      expect(b.checkpoint, isNull);
      expect(b.from, min(18));
      expect(b.at, min(18));
    });

    test('while on it, the break is the one taken', () {
      final b = breakOf([start(0), breakStart(15)], now: 17)!;
      expect(b.checkpoint, 145);
      expect(b.length, min(4));
    });

    test('after it, the next one counts from its Checkpoint', () {
      // Back at page 145; page 181 after 12 more minutes.
      final b = breakOf(
        [start(0), breakStart(15), breakEnd(19)],
        now: 20,
        checkpoints: const [145, 190],
      )!;
      expect(b.from, min(12));
      expect(b.checkpoint, 190);
      expect(b.at, min(15));
    });

    test('several breaks in one Session, each re-anchored', () {
      // The second falls at the end of a page, 14 minutes after page 145:
      // about page 187. 12 more minutes is page 223, near Checkpoint 235.
      final b = breakOf([
        start(0),
        breakStart(15),
        breakEnd(19),
        breakStart(33),
        breakEnd(36),
      ], now: 37)!;
      expect(b.checkpoint, 235);
      expect(b.at, min(16));
    });

    test('after an end-of-page break, the page is estimated by the pace', () {
      // Checkpoint 178 is too far for the first break, which falls at page
      // 136, but near enough for the second.
      final events = [start(0), breakStart(12), breakEnd(15)];
      expect(breakOf([start(0)], checkpoints: const [178])!.checkpoint, isNull);
      final b = breakOf(events, now: 16, checkpoints: const [178])!;
      expect(b.checkpoint, 178);
      expect(b.at, min(14));
    });

    test('no break is offered when the Finish comes first', () {
      expect(breakOf([start(0)], now: 1, startPage: 230), isNull);
    });

    test('a break due on reading time alone has reached no Checkpoint', () {
      final b = breakOf([start(0)], now: 13)!;
      expect(b.checkpoint, 145);
      expect(b.reached, isFalse);
    });

    test('a Checkpoint marked done makes the break due right there', () {
      // Faster than the pace: chapter 145 is done 9 minutes in, not 15.
      final b = breakOf([start(0), done(9, 145)], now: 10)!;
      expect(b.checkpoint, 145);
      expect(b.reached, isTrue);
      expect(b.from, min(9));
      expect(b.at, min(9));
      expect(b.length, min(3));
    });

    test('a Checkpoint marked without a pace still makes the break due', () {
      final b = breakOf([start(0), done(4, 115)], now: 5, perPage: null)!;
      expect(b.checkpoint, 115);
      expect(b.reached, isTrue);
      expect(b.from, min(4));
    });

    test('after a break at a marked Checkpoint, the next counts from it', () {
      // Back at page 145 after 9 minutes; page 181 after 12 more.
      final b = breakOf(
        [start(0), done(9, 145), breakStart(9), breakEnd(12)],
        now: 13,
        checkpoints: const [145, 190],
      )!;
      expect(b.from, min(12));
      expect(b.checkpoint, 190);
      expect(b.at, min(15));
      expect(b.reached, isFalse);
    });

    test('a break taken on time alone counts on from the pace, not the '
        'Checkpoint it was aimed at', () {
      // Taken at 12 minutes, page 136, three minutes short of 145.
      final b = breakOf(
        [start(0), breakStart(12), breakEnd(15)],
        now: 16,
        checkpoints: const [145, 172],
      )!;
      // 12 more minutes from page 136 is page 172.
      expect(b.checkpoint, 172);
      expect(b.at, min(12));
    });

    test('a nudge after a marked Checkpoint moves the break on from it', () {
      // Later, from page 145 at 9 minutes: 6 minutes on is page 163, and
      // the Checkpoint at 175 is 4 minutes further.
      final b = breakOf([start(0), done(9, 145), nudge(9)], now: 10)!;
      expect(b.from, min(15));
      expect(b.checkpoint, 175);
      expect(b.at, min(19));
      expect(b.reached, isFalse);
    });

    test('a Checkpoint marked on a break is ignored', () {
      final s = reduce([start(0), breakStart(12), done(13, 145)], now: 14);
      expect(s.checkpoints, isEmpty);
    });
  });

  group('the reducer and Checkpoints', () {
    test('the page the Session started at comes from its Start', () {
      final s = reduce([
        SessionEvent(SessionEventKind.start, t(0), page: 100),
      ], now: 1);
      expect(s.startPage, 100);
    });

    test('a Session from before pages were kept has no start page', () {
      expect(reduce([start(0)], now: 1).startPage, isNull);
    });

    test('each Checkpoint marked done is kept, in order', () {
      final s = reduce([start(0), done(5, 115), done(14, 145)], now: 15);
      expect(s.checkpoints.map((c) => c.page), [115, 145]);
      expect(s.checkpoints.last.at, t(14));
    });

    test('a Checkpoint before the Start or after Stop is ignored', () {
      final s = reduce([done(0, 115), start(1), stop(5), done(6, 145)]);
      expect(s.checkpoints, isEmpty);
    });
  });
}
