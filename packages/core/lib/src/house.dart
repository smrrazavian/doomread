import 'package:doomread_core/src/calendar.dart';

/// What lights one Window in the House. Before Friends exist, every Window
/// is the user's own.
enum HouseWindow {
  /// The Session running now; it pulses.
  yours,

  /// A Session the user started earlier tonight.
  earlierTonight,

  /// An evening before tonight with at least one Session.
  pastEvening,
}

/// The House's lit Windows at [now] (the injected clock), taken only from the
/// journal: [before] are when the user's other Sessions started.
///
/// The user's own Window comes first, then one per Session earlier tonight,
/// then one per past evening. Evenings follow [eveningOf]. A Session stamped
/// after [now] is left out, and no Window is ever made up.
List<HouseWindow> houseWindows({
  required DateTime now,
  required Iterable<DateTime> before,
}) {
  final tonight = eveningOf(now);
  final started = before.where((t) => !t.isAfter(now));
  return [
    HouseWindow.yours,
    for (final t in started)
      if (eveningOf(t) == tonight) HouseWindow.earlierTonight,
    for (final _ in {
      for (final t in started)
        if (eveningOf(t) != tonight) eveningOf(t),
    })
      HouseWindow.pastEvening,
  ];
}
