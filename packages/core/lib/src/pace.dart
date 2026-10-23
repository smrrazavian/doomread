import 'package:doomread_core/src/calendar.dart';

/// About how many evenings until the Finish, at the user's own pace for this
/// Work: the pages they got through per evening so far.
///
/// [sittings] are this Work's ended Sessions: when each started and how many
/// pages it moved the Position. Returns null until there's a pace to go by,
/// so no number is ever made up.
int? eveningsLeft({
  required int pagesLeft,
  required Iterable<({DateTime startedAt, int pages})> sittings,
}) {
  if (pagesLeft <= 0) return null;
  var pages = 0;
  for (final s in sittings) {
    if (s.pages > 0) pages += s.pages;
  }
  if (pages == 0) return null;
  final evenings = eveningsSpent(sittings.map((s) => s.startedAt));
  return (pagesLeft * evenings / pages).ceil();
}

/// How many different evenings Sessions started at [starts] fall on.
int eveningsSpent(Iterable<DateTime> starts) =>
    starts.map(eveningOf).toSet().length;

/// How long the user takes over a page of this Work: all the reading in
/// [sittings] (its ended Sessions) over all the pages they moved the
/// Position. A sitting missing either is left out, and with none left
/// there's no pace, so no page is ever guessed.
Duration? timePerPage(Iterable<({Duration reading, int pages})> sittings) {
  var reading = Duration.zero;
  var pages = 0;
  for (final s in sittings) {
    if (s.pages <= 0 || s.reading <= Duration.zero) continue;
    reading += s.reading;
    pages += s.pages;
  }
  return pages == 0 ? null : reading ~/ pages;
}
