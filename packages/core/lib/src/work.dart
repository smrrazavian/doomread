/// One thing the user intends to finish. For now, a paper book in pages.
// ponytail: paper books only; series, films and podcasts come in ticket #12.
class Work {
  Work({
    required this.id,
    required this.title,
    required this.author,
    required this.totalPages,
    required List<int> checkpoints,
  }) : checkpoints = List.unmodifiable([...checkpoints]..sort());

  final String id;
  final String title;
  final String author;
  final int totalPages;

  /// Pages where natural stopping places (chapter ends) fall, ascending.
  final List<int> checkpoints;
}
