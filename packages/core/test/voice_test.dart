import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  const locales = ['en', 'fa'];

  test('every Tone is kind after a Slip: it says what Chill says', () {
    for (final locale in locales) {
      final kind = voice(Moment.afterSlip, Tone.chill, locale);
      for (final tone in Tone.values) {
        expect(voice(Moment.afterSlip, tone, locale), kind, reason: '$tone');
      }
    }
  });

  test('every Tone has a line for every moment in every locale', () {
    for (final locale in locales) {
      for (final tone in Tone.values) {
        for (final moment in Moment.values) {
          final line = voice(moment, tone, locale, const {
            'app': 'Instagram',
            'minutes': '9',
          });
          expect(line, isNotEmpty, reason: '$locale $tone $moment');
          expect(line, isNot(contains('{')), reason: '$locale $tone $moment');
        }
      }
    }
  });

  test('facts fill the line', () {
    expect(
      voice(Moment.urge, Tone.chill, 'en', const {'app': 'TikTok'}),
      contains('TikTok'),
    );
  });

  test('a line that needs a missing fact gives way to one that does not', () {
    for (final locale in locales) {
      for (final tone in Tone.values) {
        final line = voice(Moment.urge, tone, locale);
        expect(line, isNotEmpty);
        expect(line, isNot(contains('{')));
      }
    }
  });

  test('the Tones sound different before a Slip', () {
    for (final locale in locales) {
      final lines = {
        for (final tone in Tone.values)
          voice(Moment.urge, tone, locale, const {'app': 'Instagram'}),
      };
      expect(lines, hasLength(Tone.values.length), reason: locale);
    }
  });

  test("the sample app is named in each locale's own letters", () {
    expect(sampleApp('en'), 'Instagram');
    expect(sampleApp('fa'), 'اینستاگرام');
    expect(sampleApp('de'), 'Instagram');
    expect(sampleApps.keys, copyPacks.keys);
  });

  test('an unknown locale speaks English', () {
    expect(
      voice(Moment.breakOver, Tone.spicy, 'de'),
      voice(Moment.breakOver, Tone.spicy, 'en'),
    );
  });

  group("the receipt's sign-off", () {
    final start = DateTime(2026, 10, 24, 21);
    SessionEvent at(SessionEventKind kind, int m) =>
        SessionEvent(kind, start.add(Duration(minutes: m)));
    final clean = Session.fromEvents([
      at(SessionEventKind.start, 0),
      at(SessionEventKind.urge, 5),
      at(SessionEventKind.letPass, 5),
      at(SessionEventKind.stop, 20),
    ], now: start.add(const Duration(hours: 1)));
    final slipped = Session.fromEvents([
      at(SessionEventKind.start, 0),
      at(SessionEventKind.urge, 5),
      at(SessionEventKind.slip, 5),
      at(SessionEventKind.resume, 8),
      at(SessionEventKind.stop, 20),
    ], now: start.add(const Duration(hours: 1)));

    test('without a Slip, each Tone says its receipt line', () {
      for (final locale in locales) {
        for (final tone in Tone.values) {
          expect(
            receiptSignOff(clean, tone, locale),
            voice(Moment.receipt, tone, locale),
          );
        }
      }
    });

    test('with a Slip, each Tone says its own kind line instead', () {
      for (final locale in locales) {
        final lines = <String>{};
        for (final tone in Tone.values) {
          final line = receiptSignOff(slipped, tone, locale);
          expect(line, voice(Moment.receiptAfterSlip, tone, locale));
          expect(line, isNot(voice(Moment.receipt, tone, locale)));
          lines.add(line);
        }
        expect(lines, hasLength(Tone.values.length), reason: locale);
      }
    });
  });

  test('Spicy is the default Tone', () {
    expect(Tone.byDefault, Tone.spicy);
  });
}
