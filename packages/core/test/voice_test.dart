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

  test('an unknown locale speaks English', () {
    expect(
      voice(Moment.breakOver, Tone.spicy, 'de'),
      voice(Moment.breakOver, Tone.spicy, 'en'),
    );
  });

  test('Spicy is the default Tone', () {
    expect(Tone.byDefault, Tone.spicy);
  });
}
