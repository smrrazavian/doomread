import 'package:doomread_core/src/work.dart';

/// What the user typed for a Work before it's saved. The numbers are in the
/// [kind]'s unit, as on [Work].
class WorkDraft {
  WorkDraft({
    required this.title,
    required this.author,
    required this.totalPages,
    required this.checkpoints,
    this.kind = WorkKind.paperBook,
    this.checkpointsUnreadable = false,
  });

  final String title;
  final String author;
  final WorkKind kind;
  final int totalPages;

  /// Ignored for a series, whose Checkpoints are its episodes.
  final List<int> checkpoints;

  /// The user typed Checkpoints that couldn't be read; [checkpoints] is moot.
  final bool checkpointsUnreadable;

  /// Everything wrong with this draft; empty when it can be saved.
  Set<WorkProblem> get problems => {
    if (title.trim().isEmpty) WorkProblem.noTitle,
    if (totalPages < 1) WorkProblem.noPages,
    if (checkpointsUnreadable && kind != WorkKind.series)
      WorkProblem.checkpointsUnreadable,
    // Only once the length is valid; otherwise one mistake shows twice.
    if (totalPages >= 1 &&
        !checkpointsUnreadable &&
        kind != WorkKind.series &&
        checkpoints.any((c) => c < 1 || c > totalPages))
      WorkProblem.checkpointPastEnd,
  };
}

/// [noPages] means no length, in whatever unit the Work counts.
enum WorkProblem {
  noTitle,
  noPages,
  checkpointsUnreadable,
  checkpointPastEnd,
}
