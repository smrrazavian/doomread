/// What the user typed for a Work before it's saved.
class WorkDraft {
  WorkDraft({
    required this.title,
    required this.author,
    required this.totalPages,
    required this.checkpoints,
  });

  final String title;
  final String author;
  final int totalPages;
  final List<int> checkpoints;

  /// Everything wrong with this draft; empty when it can be saved.
  Set<WorkProblem> get problems => {
    if (title.trim().isEmpty) WorkProblem.noTitle,
    if (totalPages < 1) WorkProblem.noPages,
    // Only once the page count is valid; otherwise one mistake shows twice.
    if (totalPages >= 1 && checkpoints.any((c) => c < 1 || c > totalPages))
      WorkProblem.checkpointPastEnd,
  };
}

enum WorkProblem { noTitle, noPages, checkpointPastEnd }
