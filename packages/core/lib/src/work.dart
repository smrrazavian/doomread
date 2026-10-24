/// What a Work is. The names are stored, so they never change.
enum WorkKind {
  paperBook,
  ebook,
  series,
  film,
  podcast,

  /// Something to get done in a sitting or a few: no length, Position,
  /// Checkpoints or Road, and never in the Library or current.
  task;

  /// The kinds the Library holds, which the user adds there.
  static const List<WorkKind> media = [paperBook, ebook, series, film, podcast];

  /// What its length, Position and Checkpoints count.
  // ponytail: a Task has none; it says pages so the switches on a unit
  // stay as they are, and no Task screen ever shows one.
  WorkUnit get unit => switch (this) {
    paperBook || ebook || task => WorkUnit.page,
    series => WorkUnit.episode,
    film || podcast => WorkUnit.second,
  };

  /// The kind of attention it takes. The Longest stretch and the Aim are
  /// kept apart for each.
  Attention get attention => switch (this) {
    paperBook || ebook => Attention.reading,
    series || film || podcast => Attention.watching,
    task => Attention.working,
  };

  /// Whether the user watches or listens to it, for the copy that says so.
  bool get watched => attention == Attention.watching;
}

/// Reading, watching (or listening), or working on a Task.
enum Attention { reading, watching, working }

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

/// The chapter [checkpoint] ends in [work], counting from 1.
int chapterEndingAt(Work work, int checkpoint) =>
    work.checkpoints.indexOf(checkpoint) + 1;
