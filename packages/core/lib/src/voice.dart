import 'package:doomread_core/src/voice_en.dart';
import 'package:doomread_core/src/voice_fa.dart';

/// The voice the app speaks in, chosen by the user.
enum Tone {
  /// Gentle, no roasting.
  chill,

  /// A light roast before a Slip, kind after it.
  spicy,

  /// Full Iranian mom (مامان‌مود).
  mom;

  static const Tone byDefault = spicy;
}

/// A moment the app speaks at.
enum Moment {
  /// The "not yet" headline. Facts: app, when known.
  urge,

  /// The headline when the user comes back after a Slip.
  afterSlip,

  /// The Planned break is here. Facts: minutes, its length.
  breakHere,

  /// The Planned break is over.
  breakOver,

  /// End of the evening, under how long the longest Stretch was.
  evening,

  /// The Aim is reached: a new Longest stretch.
  newBest,
}

/// The lines for each Tone and moment, first choice first.
typedef CopyPack = Map<Tone, Map<Moment, List<String>>>;

/// The copy packs by locale. Swap a pack to refresh the jokes; the code
/// doesn't change.
const Map<String, CopyPack> copyPacks = {'en': en, 'fa': fa};

/// The app the Tone picker and the demo Urge name, by locale, before any
/// real Watched app has opened.
const Map<String, String> sampleApps = {'en': enSampleApp, 'fa': faSampleApp};

/// [sampleApps]' name in [locale], English for an unknown one.
String sampleApp(String locale) => sampleApps[locale] ?? sampleApps['en']!;

final _placeholder = RegExp(r'\{(\w+)\}');

/// The line for [moment] in [tone] and [locale], with [facts] filled in:
/// the first line whose facts are all given.
///
/// After a Slip every Tone says what Chill says. A roast there starts the
/// what-the-hell spiral, so this rule lives here, where no screen can break
/// it.
String voice(
  Moment moment,
  Tone tone,
  String locale, [
  Map<String, String> facts = const {},
]) {
  final pack = copyPacks[locale] ?? copyPacks['en']!;
  final lines = pack[moment == Moment.afterSlip ? Tone.chill : tone]![moment]!;
  final line = lines.firstWhere(
    (l) => _placeholder.allMatches(l).every((m) => facts.containsKey(m[1])),
    orElse: () => lines.last,
  );
  return line.replaceAllMapped(_placeholder, (m) => facts[m[1]] ?? '');
}
