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
}
