import 'package:doomread/data/repositories/session_repository.dart';

/// What the Finish poster says beyond the Finish itself: how many Urges the
/// user let pass on the Work, and its last Note (null when there's none).
typedef PosterExtras = ({int urgesLetPass, String? lastNote});

/// Works out [PosterExtras] for [workId] from every Session in [records],
/// which come oldest first as [SessionRepository.watchAll] gives them,
/// measured at [now].
PosterExtras posterExtras(
  String workId,
  Iterable<SessionRecord> records,
  DateTime now,
) {
  var urges = 0;
  String? note;
  for (final r in records) {
    if (r.road.work.id != workId) continue;
    urges += r.at(now).urgesLetPass;
    if (r.note.trim().isNotEmpty) note = r.note.trim();
  }
  return (urgesLetPass: urges, lastNote: note);
}
