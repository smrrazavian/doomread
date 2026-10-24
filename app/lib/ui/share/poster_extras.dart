import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread_core/doomread_core.dart';

/// What the Finish poster says beyond the Finish itself: how many Urges the
/// user let pass on the Work, and its last Note (null when there's none).
typedef PosterExtras = ({int urgesLetPass, String? lastNote});

/// Works out [PosterExtras] for [workId] from every Session in [records],
/// which come oldest first, as [SessionRepository.watchAll] gives them.
PosterExtras posterExtras(String workId, Iterable<SessionRecord> records) {
  var urges = 0;
  String? note;
  for (final r in records) {
    if (r.road.work.id != workId) continue;
    urges += lettingPass(r.events);
    if (r.note.trim().isNotEmpty) note = r.note.trim();
  }
  return (urgesLetPass: urges, lastNote: note);
}

/// How many Urges in one Session's journal ended as Let pass. Like the
/// reducer in core, an Urge only opens while a Stretch runs, and a Let pass
/// counts only for an open one, so a double tap can't count twice.
int lettingPass(Iterable<SessionEvent> events) {
  final ordered = events.indexed.toList()
    ..sort((a, b) {
      final byTime = a.$2.at.compareTo(b.$2.at);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  var started = false;
  var running = false;
  var onBreak = false;
  var open = false;
  var passed = 0;
  for (final (_, e) in ordered) {
    switch (e.kind) {
      case SessionEventKind.start:
        if (started) continue;
        started = running = true;
      case _ when !started:
        continue;
      case SessionEventKind.pause:
        running = false;
      case SessionEventKind.resume:
      case SessionEventKind.breakEnd:
        running = true;
        onBreak = false;
      case SessionEventKind.breakStart:
        running = false;
        onBreak = true;
        open = false;
      case SessionEventKind.urge:
        if (running && !onBreak) open = true;
      case SessionEventKind.letPass:
        if (open) passed++;
        open = false;
      case SessionEventKind.slip:
        if (open) running = false;
        open = false;
      case SessionEventKind.nudge:
        break;
      case SessionEventKind.stop:
        return passed;
    }
  }
  return passed;
}
