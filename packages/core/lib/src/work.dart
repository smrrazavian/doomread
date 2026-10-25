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
    int estimated = 0,
  }) : checkpoints = List.unmodifiable(
         // A series stops naturally at the end of every episode.
         kind == WorkKind.series
             ? [for (var e = 1; e < totalPages; e++) e]
             : ([...checkpoints]..sort()),
       ),
       estimated = kind == WorkKind.series
           ? 0
           : estimated.clamp(0, checkpoints.length);

  final String id;
  final String title;
  final String author;
  final WorkKind kind;

  /// The length, in the [kind]'s unit.
  final int totalPages;

  /// Where natural stopping places fall, ascending: chapter ends, episode
  /// ends or timestamps.
  final List<int> checkpoints;

  /// How many of the last [checkpoints] are estimates: spread evenly from a
  /// chapter count, not known. Marking one done makes it real.
  final int estimated;

  /// Whether [checkpoint] is one of the estimates.
  bool isEstimate(int checkpoint) {
    final i = checkpoints.indexOf(checkpoint);
    return i >= 0 && i >= checkpoints.length - estimated;
  }
}

/// Checkpoints, with how many of the last are estimates.
typedef Checkpoints = ({List<int> checkpoints, int estimated});

/// Where [chapters] chapters end in a Work [length] long: the [known]
/// Checkpoints as they are, then the rest spread evenly from the last of
/// them to the end, as estimates. The last chapter ends at the end, which
/// is the Finish, not a Checkpoint; no two end on one page.
Checkpoints spreadCheckpoints(
  int length,
  int chapters, {
  List<int> known = const [],
}) {
  final kept = [...known.where((c) => c > 0 && c < length)]..sort();
  final from = kept.lastOrNull ?? 0;
  final rest = chapters - 1 - kept.length;
  final spread = <int>[];
  for (var i = 1; i <= rest; i++) {
    final c = from + ((length - from) * i / (rest + 1)).round();
    if (c > (spread.lastOrNull ?? from) && c < length) spread.add(c);
  }
  return (checkpoints: [...kept, ...spread], estimated: spread.length);
}

/// [work]'s Checkpoints once the user says the next one after [position]
/// really ended on [page]: that estimate becomes [page], and the estimates
/// after it spread again from there to the end, so the chapter count stays.
/// Null when the next one isn't an estimate, or [page] isn't after
/// [position] and short of the end.
Checkpoints? reachCheckpoint(
  Work work, {
  required int position,
  required int page,
}) {
  if (page <= position || page >= work.totalPages) return null;
  final cs = work.checkpoints;
  final i = cs.indexWhere((c) => c > position);
  if (i < 0 || cs[i] >= work.totalPages || !work.isEstimate(cs[i])) {
    return null;
  }
  return spreadCheckpoints(
    work.totalPages,
    cs.length + 1,
    known: [...cs.take(i), page],
  );
}

/// The chapter [checkpoint] ends in [work], counting from 1.
int chapterEndingAt(Work work, int checkpoint) =>
    work.checkpoints.indexOf(checkpoint) + 1;
