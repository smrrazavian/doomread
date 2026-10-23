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
    starts.map(_evening).toSet().length;

/// The evening a time belongs to. Reading past midnight still counts toward
/// the evening before, so the day turns over at 4 in the morning.
DateTime _evening(DateTime t) {
  final shifted = t.subtract(const Duration(hours: 4));
  return DateTime(shifted.year, shifted.month, shifted.day);
}
