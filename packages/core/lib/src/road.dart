import 'dart:math' as math;

import 'package:doomread_core/src/work.dart';

/// How far along a Road must be, at the least, for [Road.nearEnd].
const nearEndShare = 0.9;

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

  /// Whether the Finish is close enough to offer mid-Session: the Position
  /// has reached the last Checkpoint and [nearEndShare] of the length,
  /// whichever comes later, so one early Checkpoint doesn't count. A
  /// Checkpoint at the end is the end itself, not one before it.
  bool get nearEnd {
    if (finished) return false;
    final last =
        work.checkpoints.where((c) => c < work.totalPages).lastOrNull ?? 0;
    return position >= math.max(last, work.totalPages * nearEndShare);
  }

  /// The next Checkpoint ahead, if any.
  int? get next {
    for (final c in work.checkpoints) {
      if (c > position) return c;
    }
    return null;
  }
}
