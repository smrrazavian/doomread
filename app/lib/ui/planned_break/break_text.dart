import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';

// Where a Planned break falls, said in the Work's unit: the end of a
// chapter, the end of an episode, or a timestamp. A null checkpoint is the
// end of the page, or for a watched Work, the end of the segment. Only a
// Checkpoint the user marked done is ever said to be done.

/// The line on Reading about [offer]: while [minutes] of reading are still
/// to go, where it is and about how far away; once due, the Checkpoint the
/// user marked done, or else the [read] minutes so far, with no claim
/// about where they are.
String breakLine(
  AppLocalizations l10n,
  Locale locale,
  Work work,
  PlannedBreak offer, {
  required int minutes,
  required int read,
}) {
  final checkpoint = offer.checkpoint;
  final soon = minutes > 0;
  if (checkpoint != null && (soon || offer.reached)) {
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
        break;
    }
  }
  if (checkpoint != null && work.kind.unit == WorkUnit.second) {
    // A timestamp is on the player for the user to see, so it's no claim.
    final at = formatClock(Duration(seconds: checkpoint), locale);
    return soon
        ? l10n.nextBreakAtTimestamp(at, minutes)
        : l10n.breakDueAtTimestamp(at);
  }
  if (work.kind.watched) {
    return soon
        ? l10n.nextBreakWatching(minutes)
        : l10n.breakDueAfterWatching(read);
  }
  return soon ? l10n.nextBreakAtPage(minutes) : l10n.breakDueAfterReading(read);
}

/// The chip on the break, and the button that marks a Checkpoint done: the
/// chapter or episode that ends at [checkpoint]; null for a timestamp or
/// the end of the page.
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
