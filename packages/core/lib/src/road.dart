import 'package:doomread_core/src/work.dart';

/// The path from the start of a [Work] to its end, seen from a Position.
class Road {
  Road(this.work, {required int position})
    : position = position.clamp(0, work.totalPages);

  final Work work;

  /// The page the user has reached.
  final int position;

  /// How far along, from 0 to 1.
  double get progress => position / work.totalPages;

  /// Whether the Position has reached the Work's end: the Finish.
  bool get finished => position >= work.totalPages;

  /// Checkpoints at or behind the Position.
  List<int> get passed =>
      work.checkpoints.where((c) => c <= position).toList(growable: false);

  /// The next Checkpoint ahead, if any.
  int? get next {
    for (final c in work.checkpoints) {
      if (c > position) return c;
    }
    return null;
  }
}
