/// What a Work is. The names are stored, so they never change.
enum WorkKind {
  paperBook,
  ebook,
  series,
  film,
  podcast;

  /// What its length, Position and Checkpoints count.
  WorkUnit get unit => switch (this) {
    paperBook || ebook => WorkUnit.page,
    series => WorkUnit.episode,
    film || podcast => WorkUnit.second,
  };

  /// Whether the user reads it or watches it. The Longest stretch and the Aim
  /// are kept apart for the two.
  bool get watched => unit != WorkUnit.page;
}

/// What a Work's numbers count: pages, episodes, or seconds into it (shown
/// as a timestamp).
enum WorkUnit { page, episode, second }

/// One thing the user intends to finish.
///
/// Its numbers ([totalPages], the [checkpoints], and the Position on its
/// Road) are all in the [kind]'s [WorkKind.unit]: pages, episodes or seconds.
// ponytail: the names still say "page" so the branches built on them merge
// as they are; a unit-neutral rename can follow.
class Work {
  Work({
    required this.id,
    required this.title,
    required this.author,
    required this.totalPages,
    required List<int> checkpoints,
    this.kind = WorkKind.paperBook,
  }) : checkpoints = List.unmodifiable(
         // A series stops naturally at the end of every episode.
         kind == WorkKind.series
             ? [for (var e = 1; e < totalPages; e++) e]
             : ([...checkpoints]..sort()),
       );

  final String id;
  final String title;
  final String author;
  final WorkKind kind;

  /// The length, in the [kind]'s unit.
  final int totalPages;

  /// Where natural stopping places fall, ascending: chapter ends, episode
  /// ends or timestamps.
  final List<int> checkpoints;
}
