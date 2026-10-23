import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

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
}
