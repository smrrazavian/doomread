import 'package:doomread_core/src/work.dart';

/// The path from the start of a [Work] to its end, seen from a Position.
class Road {
  Road(this.work, {required int position})
    : position = position.clamp(0, work.totalPages);

  final Work work;

  /// How far the user has got, in the Work's unit: a page, an episode, or
  /// seconds in.
  final int position;

  /// How far along, from 0 to 1.
  double get progress => position / work.totalPages;

  /// Whether the Position has reached the Work's end: the Finish.
  bool get finished => position >= work.totalPages;

  /// Checkpoints at or behind the Position.
  List<int> get passed =>
      work.checkpoints.where((c) => c <= position).toList(growable: false);

  /// Whether the end is close enough to offer the Finish mid-Session: past
  /// the last Checkpoint, or without any, in the last 5%. Not once finished.
  bool get nearEnd {
    if (finished) return false;
    final last = work.checkpoints.lastOrNull;
    return last == null ? position >= work.totalPages * 0.95 : position >= last;
  }

  /// The next Checkpoint ahead, if any.
  int? get next {
    for (final c in work.checkpoints) {
      if (c > position) return c;
    }
    return null;
  }
}
