import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  WorkDraft draft({
    String title = 'Dune',
    int pages = 412,
    List<int> cp = const [],
  }) => WorkDraft(title: title, author: '', totalPages: pages, checkpoints: cp);

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
}
