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
  final evenings = <DateTime>{};
  var pages = 0;
  for (final s in sittings) {
    evenings.add(eveningOf(s.startedAt));
    if (s.pages > 0) pages += s.pages;
  }
  if (pages == 0) return null;
  return (pagesLeft * evenings.length / pages).ceil();
}
