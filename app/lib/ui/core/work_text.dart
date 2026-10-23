import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

// A Work's numbers in words, in its own unit: pages, episodes or timestamps.

/// [n] of [work]'s unit as the user types it: 142, or 1:12:20 for seconds.
String formatAmount(BuildContext context, Work work, int n) {
  final locale = Localizations.localeOf(context);
  return work.kind.unit == WorkUnit.second
      ? formatClock(Duration(seconds: n), locale)
      : formatNumber(n, locale);
}

/// "Page 142 of 245", "Episode 6 of 10" or "1:12:20 of 2:41:00". It needs
/// no context, so the home screen widget says it too.
String positionOf(AppLocalizations l10n, Locale locale, Road road) {
  final (at, total) = (road.position, road.work.totalPages);
  String clock(int s) => formatClock(Duration(seconds: s), locale);
  return switch (road.work.kind.unit) {
    WorkUnit.page => l10n.pageOf(at, total),
    WorkUnit.episode => l10n.episodeOf(at, total),
    WorkUnit.second => l10n.timeOf(clock(at), clock(total)),
  };
}

/// How much of the Work is left after its Position.
String amountLeft(BuildContext context, Road road) {
  final l10n = AppLocalizations.of(context);
  final left = road.work.totalPages - road.position;
  return switch (road.work.kind.unit) {
    WorkUnit.page => l10n.pagesLeft(left),
    WorkUnit.episode => l10n.episodesLeft(left),
    WorkUnit.second => l10n.timeLeft(formatAmount(context, road.work, left)),
  };
}

/// Where the next Checkpoint is; null when there's none ahead.
String? nextCheckpoint(BuildContext context, Road road) {
  final l10n = AppLocalizations.of(context);
  final next = road.next;
  if (next == null) return null;
  return switch (road.work.kind.unit) {
    WorkUnit.page => l10n.nextCheckpoint(next),
    WorkUnit.episode => l10n.nextEpisode(next),
    WorkUnit.second => l10n.nextTimestamp(
      formatAmount(context, road.work, next),
    ),
  };
}

/// The part of [work] a Session covered: "p. 142–156", "ep. 3–5".
String rangeOf(BuildContext context, Work work, int from, int to) {
  final l10n = AppLocalizations.of(context);
  return switch (work.kind.unit) {
    WorkUnit.page => l10n.pageRange(from, to),
    WorkUnit.episode => l10n.episodeRange(from, to),
    WorkUnit.second => l10n.timeRange(
      formatAmount(context, work, from),
      formatAmount(context, work, to),
    ),
  };
}

/// What finishing took, under the ceremony's title.
String finishedSub(BuildContext context, Finish finish) {
  final l10n = AppLocalizations.of(context);
  final (n, evenings) = (finish.pages, finish.evenings);
  return switch (finish.work.kind.unit) {
    WorkUnit.page => l10n.finishedSub(n, evenings),
    WorkUnit.episode => l10n.finishedSubEpisodes(n, evenings),
    WorkUnit.second => l10n.finishedSubTime(
      formatAmount(context, finish.work, n),
      evenings,
    ),
  };
}

/// One floor's line under the Building.
String floorDetails(BuildContext context, Finish finish) {
  final l10n = AppLocalizations.of(context);
  final (n, evenings) = (finish.pages, finish.evenings);
  return switch (finish.work.kind.unit) {
    WorkUnit.page => l10n.floorDetails(n, evenings),
    WorkUnit.episode => l10n.floorDetailsEpisodes(n, evenings),
    WorkUnit.second => l10n.floorDetailsTime(
      formatAmount(context, finish.work, n),
      evenings,
    ),
  };
}

String kindName(AppLocalizations l10n, WorkKind kind) => switch (kind) {
  WorkKind.paperBook => l10n.kindPaperBook,
  WorkKind.ebook => l10n.kindEbook,
  WorkKind.series => l10n.kindSeries,
  WorkKind.film => l10n.kindFilm,
  WorkKind.podcast => l10n.kindPodcast,
};

IconData kindIcon(WorkKind kind) => switch (kind) {
  WorkKind.paperBook => Icons.menu_book_outlined,
  WorkKind.ebook => Icons.tablet_android_outlined,
  WorkKind.series => Icons.tv_outlined,
  WorkKind.film => Icons.movie_outlined,
  WorkKind.podcast => Icons.podcasts_outlined,
};
