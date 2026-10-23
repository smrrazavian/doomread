import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

// Where a Planned break falls, said in the Work's unit: the end of a
// chapter, the end of an episode, or a timestamp. A null checkpoint is the
// end of the page, or for a watched Work, the end of the segment.

/// The line on Reading: where the break is and, while [minutes] is above
/// zero, about how far away.
String breakLine(
  AppLocalizations l10n,
  Locale locale,
  Work work,
  int? checkpoint,
  int minutes,
) {
  final soon = minutes > 0;
  if (checkpoint == null) {
    if (work.kind.watched) {
      return soon ? l10n.nextBreakWatching(minutes) : l10n.breakDueWatching;
    }
    return soon ? l10n.nextBreakAtPage(minutes) : l10n.breakDueAtPage;
  }
  switch (work.kind.unit) {
    case WorkUnit.page:
      final chapter = chapterEndingAt(work, checkpoint);
      return soon
          ? l10n.nextBreakAtCheckpoint(chapter, minutes)
          : l10n.breakDueAtCheckpoint(chapter);
    case WorkUnit.episode:
      return soon
          ? l10n.nextBreakAtEpisode(checkpoint, minutes)
          : l10n.breakDueAtEpisode(checkpoint);
    case WorkUnit.second:
      final at = formatClock(Duration(seconds: checkpoint), locale);
      return soon
          ? l10n.nextBreakAtTimestamp(at, minutes)
          : l10n.breakDueAtTimestamp(at);
  }
}

/// The chip on the break: the chapter or episode just done; null for a
/// timestamp or the end of the page.
String? checkpointDone(AppLocalizations l10n, Work work, int? checkpoint) {
  if (checkpoint == null) return null;
  return switch (work.kind.unit) {
    WorkUnit.page => l10n.chapterDone(chapterEndingAt(work, checkpoint)),
    WorkUnit.episode => l10n.episodeDone(checkpoint),
    WorkUnit.second => null,
  };
}

/// What's waiting once the break is over.
String waitingAfter(AppLocalizations l10n, Work work, int? checkpoint) {
  if (checkpoint != null) {
    switch (work.kind.unit) {
      case WorkUnit.page:
        return l10n.chapterWaiting(chapterEndingAt(work, checkpoint) + 1);
      case WorkUnit.episode:
        return l10n.episodeWaiting(checkpoint + 1);
      case WorkUnit.second:
        break;
    }
  }
  return l10n.workWaiting(work.title);
}

/// When the user is due back, at the wall-clock [time].
String backAt(AppLocalizations l10n, Work work, int? checkpoint, String time) {
  if (checkpoint != null) {
    switch (work.kind.unit) {
      case WorkUnit.page:
        return l10n.backToChapterAt(
          chapterEndingAt(work, checkpoint) + 1,
          time,
        );
      case WorkUnit.episode:
        return l10n.backToEpisodeAt(checkpoint + 1, time);
      case WorkUnit.second:
        break;
    }
  }
  return work.kind.watched ? l10n.backToWorkAt(time) : l10n.backToBookAt(time);
}
