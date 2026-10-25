import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

Matcher isCheckpoints(List<int> checkpoints, int estimated) =>
    isA<Checkpoints>()
        .having((c) => c.checkpoints, 'checkpoints', checkpoints)
        .having((c) => c.estimated, 'estimated', estimated);

void main() {
  Work work(WorkKind kind, int length, [List<int> checkpoints = const []]) =>
      Work(
        id: 'w',
        title: 'Dark',
        author: '',
        totalPages: length,
        checkpoints: checkpoints,
        kind: kind,
      );

  test('books are read in pages; the rest are watched', () {
    expect(WorkKind.paperBook.unit, WorkUnit.page);
    expect(WorkKind.ebook.unit, WorkUnit.page);
    expect(WorkKind.series.unit, WorkUnit.episode);
    expect(WorkKind.film.unit, WorkUnit.second);
    expect(WorkKind.podcast.unit, WorkUnit.second);
    expect(
      [
        for (final k in WorkKind.values)
          if (k.watched) k,
      ],
      [WorkKind.series, WorkKind.film, WorkKind.podcast],
    );
  });

  test('a Work is a paper book unless told otherwise', () {
    final w = Work(
      id: 'w',
      title: 'Dune',
      author: '',
      totalPages: 412,
      checkpoints: const [],
    );
    expect(w.kind, WorkKind.paperBook);
  });

  test('every episode end of a series is a Checkpoint, whatever was given', () {
    expect(work(WorkKind.series, 4, [2]).checkpoints, [1, 2, 3]);
    expect(work(WorkKind.series, 1).checkpoints, isEmpty);
  });

  test('a podcast keeps its own timestamps, in order', () {
    expect(work(WorkKind.podcast, 9660, [4340, 2550]).checkpoints, [
      2550,
      4340,
    ]);
  });

  test('a series on its Road: episode 6 of 10 has episode 7 next', () {
    final road = Road(work(WorkKind.series, 10), position: 6);
    expect(road.progress, 0.6);
    expect(road.next, 7);
  });

  group('a chapter count instead of the pages', () {
    test('10 chapters in 412 pages end about every 41 pages', () {
      expect(
        spreadCheckpoints(412, 10),
        isCheckpoints([41, 82, 124, 165, 206, 247, 288, 330, 371], 9),
      );
    });

    test('one chapter has no Checkpoint: its end is the Finish', () {
      expect(spreadCheckpoints(412, 1), isCheckpoints([], 0));
      expect(spreadCheckpoints(412, 0), isCheckpoints([], 0));
    });

    test('more chapters than pages never puts two on one page', () {
      expect(spreadCheckpoints(3, 10), isCheckpoints([1, 2], 2));
    });

    test('known Checkpoints stay, and the rest spread on from the last', () {
      expect(
        spreadCheckpoints(300, 4, known: [100]),
        isCheckpoints([100, 167, 233], 2),
      );
      expect(
        spreadCheckpoints(300, 2, known: [100, 200]),
        isCheckpoints([100, 200], 0),
        reason: 'more known than the count asks for',
      );
      expect(
        spreadCheckpoints(150, 3, known: [100, 200]),
        isCheckpoints([100, 125], 1),
        reason: 'a known one past a shorter end goes',
      );
    });

    test('estimates are the last few; a series has none', () {
      final w = Work(
        id: 'w',
        title: 'Dune',
        author: '',
        totalPages: 300,
        checkpoints: const [100, 167, 233],
        estimated: 2,
      );
      expect(w.isEstimate(100), isFalse);
      expect(w.isEstimate(167), isTrue);
      expect(w.isEstimate(233), isTrue);
      expect(w.isEstimate(50), isFalse, reason: 'not a Checkpoint');
      expect(
        Work(
          id: 's',
          title: 'Dark',
          author: '',
          totalPages: 10,
          checkpoints: const [],
          kind: WorkKind.series,
          estimated: 3,
        ).estimated,
        0,
      );
    });
  });

  group('a chapter marked done on an estimate', () {
    // 300 pages in about 5 chapters, none known yet.
    final dune = Work(
      id: 'w',
      title: 'Dune',
      author: '',
      totalPages: 300,
      checkpoints: const [60, 120, 180, 240],
      estimated: 4,
    );

    test('the real page replaces it, and the rest spread on from there', () {
      expect(
        reachCheckpoint(dune, position: 0, page: 75),
        isCheckpoints([75, 131, 188, 244], 3),
      );
    });

    test('marked where it was guessed, it becomes real all the same', () {
      expect(
        reachCheckpoint(dune, position: 0, page: 60),
        isCheckpoints([60, 120, 180, 240], 3),
      );
    });

    test('past a later estimate, the rest still come after it', () {
      expect(
        reachCheckpoint(dune, position: 0, page: 200),
        isCheckpoints([200, 225, 250, 275], 3),
      );
    });

    test('estimates the user read past are kept as they are', () {
      expect(
        reachCheckpoint(dune, position: 130, page: 170),
        isCheckpoints([60, 120, 170, 235], 1),
      );
    });

    test('a page at or behind the Position, or at the end, is refused', () {
      expect(reachCheckpoint(dune, position: 30, page: 30), isNull);
      expect(reachCheckpoint(dune, position: 30, page: 20), isNull);
      expect(reachCheckpoint(dune, position: 30, page: 300), isNull);
    });

    test('with no estimate ahead there is nothing to refine', () {
      final known = Work(
        id: 'w',
        title: 'Dune',
        author: '',
        totalPages: 300,
        checkpoints: const [60, 120],
      );
      expect(reachCheckpoint(known, position: 0, page: 70), isNull);
      expect(reachCheckpoint(dune, position: 240, page: 260), isNull);
    });
  });
}
