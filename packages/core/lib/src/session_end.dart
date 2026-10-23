/// What the user typed on End of the evening, before it's saved.
class SessionEndDraft {
  SessionEndDraft({
    required this.page,
    required this.fromPage,
    required this.totalPages,
  });

  /// The page they stopped at; null when the field is empty or unreadable.
  final int? page;

  /// The Position when the Session started.
  final int fromPage;
  final int totalPages;

  /// Everything wrong with this draft; empty when it can be saved.
  Set<SessionEndProblem> get problems => switch (page) {
    null => {SessionEndProblem.noPage},
    final p when p < fromPage || p > totalPages => {
      SessionEndProblem.pageOutOfRange,
    },
    _ => const {},
  };
}

enum SessionEndProblem { noPage, pageOutOfRange }
