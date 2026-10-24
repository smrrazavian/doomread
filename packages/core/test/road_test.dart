import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // The Remains of the Day: 245 pages, chapters ending on these pages.
  final book = Work(
    id: 'w1',
    title: 'The Remains of the Day',
    author: 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: [34, 66, 98, 128, 156, 194, 222],
  );

  test('page 142 is 58% of the way, past four Checkpoints, next at 156', () {
    final road = Road(book, position: 142);
    expect(road.progress, closeTo(0.58, 0.005));
    expect(road.passed, [34, 66, 98, 128]);
    expect(road.next, 156);
  });

  test('a Checkpoint exactly at the Position counts as passed', () {
    final road = Road(book, position: 156);
    expect(road.passed.last, 156);
    expect(road.next, 194);
  });

  test('at page 0 nothing is passed and the first Checkpoint is next', () {
    final road = Road(book, position: 0);
    expect(road.progress, 0);
    expect(road.passed, isEmpty);
    expect(road.next, 34);
  });

  test('on the last page the Road is complete with nothing next', () {
    final road = Road(book, position: 245);
    expect(road.progress, 1);
    expect(road.next, isNull);
  });

  test('a Work without Checkpoints still has progress', () {
    final noChapters = Work(
      id: 'w2',
      title: 'Essays',
      author: 'Someone',
      totalPages: 200,
      checkpoints: const [],
    );
    final road = Road(noChapters, position: 50);
    expect(road.progress, 0.25);
    expect(road.passed, isEmpty);
    expect(road.next, isNull);
  });

  group('nearEnd', () {
    Work work(int total, List<int> checkpoints, [WorkKind? kind]) => Work(
      id: 'w',
      title: 'T',
      author: '',
      totalPages: total,
      checkpoints: checkpoints,
      kind: kind ?? WorkKind.paperBook,
    );

    test('past the last Checkpoint and 90%, but not once finished', () {
      // 245 * 0.9 = 220.5, before the last Checkpoint at 222.
      expect(Road(book, position: 221).nearEnd, isFalse);
      expect(Road(book, position: 222).nearEnd, isTrue);
      expect(Road(book, position: 245).nearEnd, isFalse);
    });

    test('one early Checkpoint does not make it near', () {
      final early = work(200, [20]);
      expect(Road(early, position: 25).nearEnd, isFalse);
      expect(Road(early, position: 179).nearEnd, isFalse);
      expect(Road(early, position: 180).nearEnd, isTrue);
    });

    test('without Checkpoints it is the last 10%', () {
      final essays = work(200, const []);
      expect(Road(essays, position: 179).nearEnd, isFalse);
      expect(Road(essays, position: 180).nearEnd, isTrue);
    });

    test('a timed Work counts in seconds', () {
      // Two hours, a timestamp at the half.
      final film = work(7200, [3600], WorkKind.film);
      expect(Road(film, position: 6479).nearEnd, isFalse);
      expect(Road(film, position: 6480).nearEnd, isTrue);
    });

    test('a Checkpoint at the end is ignored', () {
      final ending = work(200, [100, 200]);
      expect(Road(ending, position: 179).nearEnd, isFalse);
      expect(Road(ending, position: 180).nearEnd, isTrue);
    });
  });
}
