import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // An evening, measured in minutes from 21:00.
  DateTime t(int minutes, [int seconds = 0]) =>
      DateTime(2026, 10, 22, 21, minutes, seconds);
  SessionEvent e(SessionEventKind kind, int m, [int s = 0]) =>
      SessionEvent(kind, t(m, s));
  SessionEvent start(int m) => e(SessionEventKind.start, m);
  SessionEvent pause(int m) => e(SessionEventKind.pause, m);
  SessionEvent resume(int m) => e(SessionEventKind.resume, m);
  SessionEvent stop(int m) => e(SessionEventKind.stop, m);
  SessionEvent urge(int m, [int s = 0]) => e(SessionEventKind.urge, m, s);
  SessionEvent letPass(int m) => e(SessionEventKind.letPass, m);
  SessionEvent slip(int m) => e(SessionEventKind.slip, m);
  SessionEvent breakStart(int m) => e(SessionEventKind.breakStart, m);
  Session reduce(List<SessionEvent> events, {int now = 60}) =>
      Session.fromEvents(events, now: t(now));
  List<int> minutes(Session s) => [
    for (final st in s.stretches) st.length.inMinutes,
  ];

  group('Urges in the journal', () {
    test('letting an Urge pass keeps the Stretch, time on it included', () {
      final s = reduce([start(0), urge(5), letPass(7), stop(12)]);
      expect(minutes(s), [12]);
      expect(s.urgeOpen, isFalse);
      expect(s.slipped, isFalse);
    });

    test('an Urge stays open until it is let pass or slips', () {
      final s = reduce([start(0), urge(5)], now: 6);
      expect(s.urgeOpen, isTrue);
      expect(s.current, isNotNull);
    });

    test('a Slip ends the Stretch, which still counts', () {
      final s = reduce([start(0), urge(5), slip(9)]);
      expect(minutes(s), [9]);
      expect(s.stretches.single.endedBy, StretchEnd.slip);
      expect(s.slipped, isTrue);
      expect(s.current, isNull);
      final stopped = reduce([start(0), urge(5), slip(9), stop(20)]);
      expect(longestStretch([stopped]), const Duration(minutes: 9));
    });

    test('after a Slip, Resume starts a new Stretch', () {
      final s = reduce([start(0), urge(5), slip(9), resume(15), stop(18)]);
      expect(minutes(s), [9, 3]);
      expect(s.slipped, isFalse);
    });

    test('a second Urge while one is open is ignored', () {
      final s = reduce([start(0), urge(5), urge(5, 1), letPass(6)]);
      expect(s.urgeOpen, isFalse);
    });

    test('Let pass or Slip with no open Urge is ignored', () {
      final s = reduce([start(0), letPass(3), slip(4)], now: 10);
      expect(minutes(s), [10]);
      expect(s.slipped, isFalse);
    });

    test('an Urge on a Planned break, after a Slip or after Stop is '
        'ignored', () {
      expect(reduce([start(0), breakStart(5), urge(6)]).urgeOpen, isFalse);
      expect(reduce([start(0), urge(1), slip(2), urge(3)]).urgeOpen, isFalse);
      expect(reduce([start(0), stop(5), urge(6)]).urgeOpen, isFalse);
    });

    test('no Urge while paused: a Pause is never a failure', () {
      final s = reduce([start(0), pause(5), urge(6), slip(7)]);
      expect(s.paused, isTrue);
      expect(s.urgeOpen, isFalse);
      expect(s.slipped, isFalse);
      expect(s.stretches.single.endedBy, StretchEnd.pause);
    });

    test('Stop after a Slip leaves nothing slipped', () {
      expect(reduce([start(0), urge(1), slip(2), stop(3)]).slipped, isFalse);
    });
  });

  group('raisesUrge', () {
    const rules = WatchRules(watched: {'com.instagram.android'});
    bool raises(List<SessionEvent> events, String app) =>
        raisesUrge(reduce(events, now: 30), app, rules);

    test('a Watched app raises an Urge while reading', () {
      expect(raises([start(0)], 'com.instagram.android'), isTrue);
    });

    test('an app that is not Watched never does', () {
      expect(raises([start(0)], 'org.example.reader'), isFalse);
    });

    test('a Watched app raises none while paused', () {
      expect(raises([start(0), pause(5)], 'com.instagram.android'), isFalse);
    });

    test('nothing is raised on a Planned break, or before Start or after '
        'Stop', () {
      const app = 'com.instagram.android';
      expect(raises([start(0), breakStart(5)], app), isFalse);
      expect(raises([], app), isFalse);
      expect(raises([start(0), stop(5)], app), isFalse);
    });

    test('opening anyway lands in the Watched app without a new Urge', () {
      expect(
        raises([start(0), urge(5), slip(6)], 'com.instagram.android'),
        isFalse,
      );
    });

    test('an open Urge raises no second one, but comes back up', () {
      final s = reduce([start(0), urge(5)], now: 30);
      expect(raisesUrge(s, 'com.instagram.android', rules), isFalse);
      expect(bringsUrgeBack(s, 'com.instagram.android', rules), isTrue);
      expect(bringsUrgeBack(s, 'org.example.reader', rules), isFalse);
    });

    test('settings and package installers are never Watched, so turning '
        'Doomread off or uninstalling is never in the way', () {
      const all = WatchRules(watched: {...neverWatched});
      for (final app in neverWatched) {
        expect(all.isWatched(app), isFalse, reason: app);
      }
    });

    test('Instagram and TikTok are Watched by default', () {
      const defaults = WatchRules(watched: defaultWatched);
      expect(defaults.isWatched('com.instagram.android'), isTrue);
      expect(defaults.isWatched('com.zhiliaoapp.musically'), isTrue);
    });
  });
}
