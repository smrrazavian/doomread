import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

Matcher isCheckpoints(List<int> checkpoints, int estimated) =>
    isA<Checkpoints>()
        .having((c) => c.checkpoints, 'checkpoints', checkpoints)
        .having((c) => c.estimated, 'estimated', estimated);

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

  group('with a chapter count', () {
    WorkDraft counted(
      int chapters, {
      int pages = 412,
      List<int> cp = const [],
    }) => WorkDraft(
      title: 'Dune',
      author: '',
      totalPages: pages,
      checkpoints: cp,
      chapters: chapters,
    );

    test('the Checkpoints are spread evenly, all estimates', () {
      final d = counted(4, pages: 400);
      expect(d.problems, isEmpty);
      expect(d.toSave, isCheckpoints([100, 200, 300], 3));
    });

    test('Checkpoints already known stay, and are never a problem', () {
      final d = counted(3, pages: 150, cp: [100, 200]);
      expect(d.problems, isEmpty);
      expect(d.toSave, isCheckpoints([100, 125], 1));
    });

    test('a typed list is all real', () {
      expect(draft(cp: [34, 66]).toSave, isCheckpoints([34, 66], 0));
    });

    test('in a typed list, the estimates it was shown stay estimates '
        'until changed', () {
      WorkDraft typed(List<int> cp) => WorkDraft(
        title: 'Dune',
        author: '',
        totalPages: 400,
        checkpoints: cp,
        estimates: const [200, 300],
      );
      expect(typed([100, 200, 300]).toSave, isCheckpoints([100, 200, 300], 2));
      expect(
        typed([100, 200, 310]).toSave,
        isCheckpoints([100, 200, 310], 0),
        reason: 'only the last ones can be estimates',
      );
      expect(typed([100, 250, 300]).toSave, isCheckpoints([100, 250, 300], 1));
    });

    test('with a count, typed pages stay known but for the estimates', () {
      final d = WorkDraft(
        title: 'Dune',
        author: '',
        totalPages: 400,
        checkpoints: const [90, 200, 300],
        estimates: const [200, 300],
        chapters: 3,
      );
      expect(d.toSave, isCheckpoints([90, 245], 1));
    });

    test('timestamps and a series never take a count', () {
      final film = WorkDraft(
        title: 'Dune',
        author: '',
        totalPages: 9660,
        checkpoints: const [2550],
        kind: WorkKind.film,
        chapters: 4,
      );
      expect(film.toSave, isCheckpoints([2550], 0));
    });
  });
}
