import 'package:doomread_core/src/session.dart';

// Every number here is a tunable default, from the research in the design
// doc (section 6.1): systematic breaks of 3/12 and 6/24 minutes.

/// Minutes of reading that earn one minute of Planned break.
const readingPerBreakMinute = 4;

/// Reading before the first Planned break, before the Longest stretch grows.
const shortestInterval = Duration(minutes: 12);

/// Reading before a Planned break once the Longest stretch has grown.
const longestInterval = Duration(minutes: 24);

/// No Planned break is longer than this, however long the reading.
const longestBreak = Duration(minutes: 10);

/// How much reading a Planned break asks for before it's offered: 12
/// minutes, growing with the Longest stretch in steps of 4 (so the break
/// grows a minute at a time) up to 24.
Duration breakInterval(Duration longestStretch) {
  final steps = longestStretch.inMinutes ~/ readingPerBreakMinute;
  final interval = Duration(minutes: steps * readingPerBreakMinute);
  if (interval < shortestInterval) return shortestInterval;
  if (interval > longestInterval) return longestInterval;
  return interval;
}

/// The Planned break [reading] earns: a minute per 4 minutes, rounded up to
/// a whole minute, and [longestBreak] at most.
Duration breakLength(Duration reading) {
  const perMinute = 60 * readingPerBreakMinute;
  final minutes = (reading.inSeconds + perMinute - 1) ~/ perMinute;
  final length = Duration(minutes: minutes);
  return length > longestBreak ? longestBreak : length;
}

/// A Planned break the app offers: after how much reading, and where.
///
/// Reading is counted since the Session started or the last Planned break
/// ended.
class PlannedBreak {
  const PlannedBreak({required this.from, required this.at, this.checkpoint});

  /// The reading after which it's offered.
  final Duration from;

  /// The reading after which it's expected: when the user should reach
  /// [checkpoint] at their pace, or [from] for the end of the page.
  final Duration at;

  /// The Checkpoint (a page) it's at; null means the end of the page the
  /// user is on once [from] has passed.
  final int? checkpoint;

  /// How long it is.
  Duration get length => breakLength(at);

  @override
  String toString() => 'PlannedBreak($from, $at, $checkpoint)';
}

/// Where a Planned break offered after [from] of reading falls, when that
/// reading started at [fromPage] and the user reads a page every [perPage].
///
/// It's the first Checkpoint after [from], unless reaching that would take
/// more than half the [interval] longer: then it's the end of the page the
/// user is on. With no pace ([perPage] null), no page is guessed, so it's
/// always the end of the page. Null when the Finish comes first.
PlannedBreak? placeBreak({
  required Duration interval,
  required Duration from,
  required int fromPage,
  required int totalPages,
  required List<int> checkpoints,
  Duration? perPage,
}) {
  final endOfPage = PlannedBreak(from: from, at: from);
  if (perPage == null || perPage <= Duration.zero) return endOfPage;
  final pageThen = fromPage + from.inMicroseconds / perPage.inMicroseconds;
  if (pageThen >= totalPages) return null;
  for (final c in checkpoints) {
    if (c < pageThen) continue;
    if (c >= totalPages) break;
    final at = perPage * (c - fromPage);
    return at - from <= interval ~/ 2
        ? PlannedBreak(from: from, at: at, checkpoint: c)
        : endOfPage;
  }
  return endOfPage;
}

/// The Planned break of [session] now: the one the user is on, or else the
/// one on offer. Null when the Finish comes first.
///
/// The Session started at [startPage]; [longestStretch] is from the
/// Sessions before it, and [perPage] is the user's pace in this Work, if
/// there is one yet. Each nudge moves the offer half an interval later.
/// After a break, the next one is counted from its Checkpoint, or from the
/// page the pace says the user had reached.
PlannedBreak? plannedBreak(
  Session session, {
  required Duration longestStretch,
  required int startPage,
  required int totalPages,
  required List<int> checkpoints,
  Duration? perPage,
}) {
  final interval = breakInterval(longestStretch);
  PlannedBreak? offerFrom(Duration from, int page) => placeBreak(
    interval: interval,
    from: from,
    fromPage: page,
    totalPages: totalPages,
    checkpoints: checkpoints,
    perPage: perPage,
  );

  PlannedBreak? offerBetween(DateTime? since, DateTime? until, int page) {
    var offer = offerFrom(interval, page);
    for (final n in session.nudges) {
      if (offer == null) break;
      if (since != null && n.isBefore(since)) continue;
      if (until != null && !n.isBefore(until)) continue;
      offer = offerFrom(offer.at + interval ~/ 2, page);
    }
    return offer;
  }

  var since = session.startedAt;
  var page = startPage;
  for (final b in session.breaks) {
    final taken = offerBetween(since, b.start, page);
    if (b.end == null) return taken;
    final reading = session.readingBetween(since, b.start);
    page =
        taken?.checkpoint ??
        (perPage == null || perPage <= Duration.zero
            ? page
            : page + (reading.inMicroseconds / perPage.inMicroseconds).round());
    since = b.end;
  }
  return offerBetween(since, null, page);
}
