import 'package:doomread_core/src/pace.dart';
import 'package:doomread_core/src/planned_break.dart';
import 'package:doomread_core/src/road.dart';
import 'package:doomread_core/src/session.dart';
import 'package:doomread_core/src/work.dart';

/// A Session with its Work, on its Road as it stands now, and the pages it
/// covered once ended on End of the evening.
typedef WorkSession = ({
  Road road,
  Session session,
  ({int from, int to})? pages,
});

/// The Sessions in [all] that take [attention]: reading, watching or
/// working. The Longest stretch and the Aim are kept apart for each, so
/// watching a film can't set the bar for reading, nor a Task for either.
Iterable<Session> alike(Iterable<WorkSession> all, Attention attention) => all
    .where((s) => s.road.work.kind.attention == attention)
    .map((s) => s.session);

/// Tonight's Aim for [attention], after the Sessions in [before].
Duration aimAfter(Iterable<WorkSession> before, Attention attention) =>
    aimFor(longestStretch(alike(before, attention)));

/// [work]'s ended Sessions in [history], each as one [PaceSitting].
List<PaceSitting> sittingsOf(Work work, Iterable<WorkSession> history) => [
  for (final s in history)
    if (s.road.work.id == work.id)
      if ((s.pages, s.session.startedAt) case (final p?, final at?))
        (
          startedAt: at,
          reading: s.session.readingBetween(at, null),
          pages: p.to - p.from,
        ),
];

/// About how many evenings until [road]'s Finish, at the pace of its ended
/// Sessions in [history]; null until there's a pace. Works in any unit,
/// since it only compares how much each evening covered.
int? eveningsLeftOn(Road road, Iterable<WorkSession> history) => eveningsLeft(
  pagesLeft: road.work.totalPages - road.position,
  sittings: sittingsOf(road.work, history),
);

/// The Planned break of [tonight] now: the Sessions [before] it, read or
/// watched alike, give the Longest stretch, and those in the same Work give
/// the pace (time per page, episode or second). Null when the Finish comes
/// first.
PlannedBreak? plannedBreakOf(
  WorkSession tonight, {
  required Iterable<WorkSession> before,
}) {
  final work = tonight.road.work;
  return plannedBreak(
    tonight.session,
    longestStretch: longestStretch(alike(before, work.kind.attention)),
    // The Position moves as Checkpoints are marked done, so it's the start
    // only for a Session from before its Start kept the page.
    startPage:
        tonight.session.startPage ??
        tonight.pages?.from ??
        tonight.road.position,
    totalPages: work.totalPages,
    checkpoints: work.checkpoints,
    perPage: timePerPage(sittingsOf(work, before)),
  );
}
