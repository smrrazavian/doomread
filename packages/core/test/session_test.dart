import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // An evening, measured in minutes from 21:00.
  DateTime t(int minutes, [int seconds = 0]) =>
      DateTime(2026, 10, 22, 21, minutes, seconds);
  SessionEvent start(int m) => SessionEvent(SessionEventKind.start, t(m));
  SessionEvent pause(int m) => SessionEvent(SessionEventKind.pause, t(m));
  SessionEvent resume(int m) => SessionEvent(SessionEventKind.resume, t(m));
  SessionEvent stop(int m) => SessionEvent(SessionEventKind.stop, t(m));
  Session reduce(List<SessionEvent> events, {int now = 60}) =>
      Session.fromEvents(events, now: t(now));
  List<int> minutes(Session s) => [
    for (final st in s.stretches) st.length.inMinutes,
  ];

  group('Stretches', () {
    test('Start then Stop is one Stretch, ended by the Stop', () {
      final s = reduce([start(0), stop(9)]);
      expect(minutes(s), [9]);
      expect(s.stretches.single.endedBy, StretchEnd.stop);
      expect(s.stopped, isTrue);
      expect(s.startedAt, t(0));
    });

    test('a Pause ends the Stretch and Resume starts a new one', () {
      final s = reduce([start(0), pause(5), resume(7), stop(15)]);
      expect(minutes(s), [5, 8]);
      expect(s.stretches.first.endedBy, StretchEnd.pause);
      expect(s.stretches.last.endedBy, StretchEnd.stop);
    });

    test('a Pause is never a Slip: it is recorded only as a Pause', () {
      final s = reduce([start(0), pause(5), resume(6), pause(8), resume(9)]);
      expect(s.stretches.map((st) => st.endedBy), [
        StretchEnd.pause,
        StretchEnd.pause,
        null,
      ]);
    });

    test('time spent paused is in no Stretch', () {
      final s = reduce([start(0), pause(5), stop(30)]);
      expect(minutes(s), [5]);
      expect(s.longestStretch, const Duration(minutes: 5));
    });

    test('a running Stretch is measured up to the injected now', () {
      final s = Session.fromEvents([
        start(0),
        pause(2),
        resume(3),
      ], now: t(8, 12));
      expect(s.current, isNotNull);
      expect(s.current!.length, const Duration(minutes: 5, seconds: 12));
      expect(s.stopped, isFalse);
      expect(s.paused, isFalse);
    });

    test('while paused there is no current Stretch', () {
      final s = reduce([start(0), pause(4)]);
      expect(s.current, isNull);
      expect(s.paused, isTrue);
      expect(minutes(s), [4]);
    });

    test('a second Pause and a Resume while running are ignored', () {
      final s = reduce([
        start(0),
        resume(1),
        pause(4),
        pause(6),
        resume(10),
        resume(12),
        stop(20),
      ]);
      expect(minutes(s), [4, 10]);
    });

    test('anything after Stop is ignored', () {
      final s = reduce([start(0), stop(5), resume(6), stop(50)]);
      expect(minutes(s), [5]);
      expect(s.paused, isFalse);
    });

    test('a second Start does not restart the Session', () {
      final s = reduce([start(0), start(3), stop(10)]);
      expect(minutes(s), [10]);
      expect(s.startedAt, t(0));
    });

    test('events before the Start are ignored', () {
      final s = reduce([
        SessionEvent(SessionEventKind.pause, t(0)),
        SessionEvent(SessionEventKind.resume, t(1)),
        start(2),
        stop(4),
      ]);
      expect(minutes(s), [2]);
    });

    test('a journal without a Start is an empty Session', () {
      final s = reduce([pause(1), stop(2)]);
      expect(s.startedAt, isNull);
      expect(s.stretches, isEmpty);
      expect(s.stopped, isFalse);
      expect(s.paused, isFalse);
    });

    test('events are replayed in time order, whatever order they come in', () {
      final s = reduce([stop(15), resume(7), start(0), pause(5)]);
      expect(minutes(s), [5, 8]);
    });

    test('events at the same instant keep their journal order', () {
      final s = reduce([start(0), pause(3), resume(3), stop(6)]);
      expect(minutes(s), [3, 3]);
    });

    test('a clock that went backwards gives a zero Stretch, not negative', () {
      final s = Session.fromEvents([start(10)], now: t(5));
      expect(s.current!.length, Duration.zero);
    });

    test('the longest Stretch of a Session is its longest one', () {
      final s = reduce([start(0), pause(3), resume(4), pause(13), resume(14)]);
      // The running one is 46 minutes at now (21:60).
      expect(s.longestStretch, const Duration(minutes: 46));
    });
  });

  group('Reopen', () {
    SessionEvent reopen(int m) => SessionEvent(SessionEventKind.reopen, t(m));

    test('undoes a Stop: the Stretch it ended goes on as if unbroken', () {
      final s = reduce([start(0), stop(9), reopen(10)]);
      expect(s.stopped, isFalse);
      expect(s.current, isNotNull);
      expect(minutes(s), [60]);
    });

    test('a Stop while paused reopens still paused', () {
      final s = reduce([start(0), pause(5), stop(9), reopen(10)]);
      expect(s.stopped, isFalse);
      expect(s.paused, isTrue);
      expect(minutes(s), [5]);
    });

    test('what comes between the Stop and the Reopen is ignored', () {
      final s = reduce([start(0), stop(9), pause(9), reopen(10)]);
      expect(s.current, isNotNull);
    });

    test('the reopened Session can stop again', () {
      final s = reduce([start(0), stop(9), reopen(10), stop(20)]);
      expect(s.stopped, isTrue);
      expect(minutes(s), [20]);
    });

    test('a Reopen with no Stop, or a second one, changes nothing', () {
      expect(minutes(reduce([start(0), pause(5), reopen(6)])), [5]);
      final twice = reduce([
        start(0),
        stop(9),
        reopen(10),
        pause(12),
        reopen(13),
      ]);
      expect(twice.paused, isTrue);
      expect(minutes(twice), [12]);
    });
  });

  group('Longest stretch and Aim', () {
    final short = reduce([start(0), stop(4)]);
    final long = reduce([start(0), pause(9), resume(10), stop(12)]);
    final open = reduce([start(0)]); // left running, say the app was killed

    test('is the longest Stretch across stopped Sessions', () {
      expect(longestStretch([short, long]), const Duration(minutes: 9));
    });

    test('ignores a Session that was never stopped', () {
      expect(longestStretch([short, open]), const Duration(minutes: 4));
    });

    test('is zero with no Sessions yet', () {
      expect(longestStretch(const []), Duration.zero);
    });

    test('the Aim is the Longest stretch plus one minute', () {
      expect(aimFor(const Duration(minutes: 9)), const Duration(minutes: 10));
      expect(aimFor(Duration.zero), const Duration(minutes: 1));
    });

    test('the Aim is rounded up to a whole minute', () {
      const best = Duration(minutes: 5, seconds: 12);
      expect(aimFor(best), const Duration(minutes: 7));
      expect(aimFor(const Duration(minutes: 5)), const Duration(minutes: 6));
    });
  });

  group('new best stretch', () {
    final nine = reduce([start(0), stop(9)]);
    final twelve = reduce([start(0), stop(12)]);

    test('when tonight beats every Session before', () {
      expect(isNewBest(twelve, [nine]), isTrue);
    });

    test('not when tonight only ties or falls short', () {
      expect(isNewBest(nine, [nine]), isFalse);
      expect(isNewBest(nine, [twelve]), isFalse);
    });

    test('the first Session counts, if it has any time in it', () {
      expect(isNewBest(nine, const []), isTrue);
      expect(isNewBest(reduce([start(0), stop(0)]), const []), isFalse);
    });

    test('a Pause splits time, so two short Stretches are not a best', () {
      final split = reduce([start(0), pause(6), resume(7), stop(13)]);
      expect(isNewBest(split, [nine]), isFalse);
    });
  });

  group('Urges let pass', () {
    SessionEvent at(SessionEventKind kind, int m) => SessionEvent(kind, t(m));

    test('count each Urge that ended in going back', () {
      final s = reduce([
        start(0),
        at(SessionEventKind.urge, 3),
        at(SessionEventKind.letPass, 3),
        at(SessionEventKind.urge, 9),
        at(SessionEventKind.slip, 9),
        resume(12),
        at(SessionEventKind.urge, 15),
        at(SessionEventKind.letPass, 15),
        stop(20),
      ]);
      expect(s.urgesLetPass, 2);
    });

    test('a double tap, or a Let pass with no Urge, is not another', () {
      final s = reduce([
        start(0),
        at(SessionEventKind.letPass, 1),
        at(SessionEventKind.urge, 3),
        at(SessionEventKind.letPass, 3),
        at(SessionEventKind.letPass, 3),
        stop(20),
        at(SessionEventKind.urge, 21),
        at(SessionEventKind.letPass, 21),
      ]);
      expect(s.urgesLetPass, 1);
    });

    test('nothing opens an Urge on a Pause or the Planned break', () {
      final s = reduce([
        start(0),
        pause(2),
        at(SessionEventKind.urge, 3),
        at(SessionEventKind.letPass, 3),
        resume(4),
        at(SessionEventKind.breakStart, 10),
        at(SessionEventKind.urge, 11),
        at(SessionEventKind.letPass, 11),
        at(SessionEventKind.breakEnd, 15),
        at(SessionEventKind.urge, 16),
        at(SessionEventKind.letPass, 16),
      ]);
      expect(s.urgesLetPass, 1);
    });
  });

  group('the receipt numbers', () {
    SessionEvent at(SessionEventKind kind, int m) => SessionEvent(kind, t(m));

    test('a Slip counts once; a Let pass and a Pause never do', () {
      final s = reduce([
        start(0),
        at(SessionEventKind.urge, 3),
        at(SessionEventKind.letPass, 3),
        at(SessionEventKind.urge, 9),
        at(SessionEventKind.slip, 9),
        at(SessionEventKind.slip, 9),
        resume(12),
        pause(14),
        resume(15),
        stop(20),
      ]);
      expect(s.slips, 1);
      expect(reduce([start(0), pause(4), resume(5), stop(9)]).slips, 0);
    });

    test('reading leaves out Pauses and the Planned break', () {
      final s = reduce([
        start(0),
        pause(5),
        resume(7),
        at(SessionEventKind.breakStart, 15),
        at(SessionEventKind.breakEnd, 20),
        stop(30),
      ]);
      expect(s.reading, const Duration(minutes: 23));
      expect(s.breaks, hasLength(1));
      expect(reduce(const []).reading, Duration.zero);
    });
  });
}
