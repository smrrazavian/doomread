import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  WorkDraft draft({
    String title = 'Dune',
    int pages = 412,
    List<int> cp = const [],
    WorkKind kind = WorkKind.paperBook,
    bool unreadable = false,
  }) => WorkDraft(
    title: title,
    author: '',
    totalPages: pages,
    checkpoints: cp,
    kind: kind,
    checkpointsUnreadable: unreadable,
  );

  test('a titled Work with pages and in-range Checkpoints has no problems', () {
    expect(draft(cp: [1, 200, 412]).problems, isEmpty);
  });

  test('zero pages is one problem, not also every Checkpoint', () {
    expect(draft(pages: 0, cp: [34, 66]).problems, {WorkProblem.noPages});
  });

  test('a Checkpoint before page 1 or after the last page is a problem', () {
    expect(draft(cp: [0]).problems, {WorkProblem.checkpointPastEnd});
    expect(draft(cp: [413]).problems, {WorkProblem.checkpointPastEnd});
  });

  test('unreadable Checkpoints are a format problem, not past the end', () {
    expect(draft(unreadable: true).problems, {
      WorkProblem.checkpointsUnreadable,
    });
    expect(draft(pages: 0, unreadable: true).problems, {
      WorkProblem.noPages,
      WorkProblem.checkpointsUnreadable,
    });
  });

  test('a series needs episodes, and its Checkpoints are never asked', () {
    expect(draft(kind: WorkKind.series, pages: 0).problems, {
      WorkProblem.noPages,
    });
    expect(draft(kind: WorkKind.series, pages: 10, cp: [-1]).problems, isEmpty);
  });

  test('a film timestamp past its length is a problem', () {
    final film = draft(kind: WorkKind.film, pages: 9660, cp: [9661]);
    expect(film.problems, {WorkProblem.checkpointPastEnd});
  });
}
