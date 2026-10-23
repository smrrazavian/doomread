import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  PaceSitting sat(int day, int hour, int pages) => (
    startedAt: DateTime(2026, 10, day, hour),
    reading: const Duration(minutes: 30),
    pages: pages,
  );

  test('no estimate before any Session ends', () {
    expect(eveningsLeft(pagesLeft: 103, sittings: const []), isNull);
  });

  test('no estimate when no pages were read yet', () {
    expect(eveningsLeft(pagesLeft: 103, sittings: [sat(20, 21, 0)]), isNull);
  });

  test('103 pages left at 28 pages an evening is about four evenings', () {
    final sittings = [sat(18, 21, 30), sat(19, 22, 26)];
    expect(eveningsLeft(pagesLeft: 103, sittings: sittings), 4);
  });

  test('two Sessions on one evening count as one evening', () {
    final sittings = [sat(20, 20, 10), sat(20, 22, 10)];
    expect(eveningsLeft(pagesLeft: 40, sittings: sittings), 2);
  });

  test('reading past midnight still belongs to the evening before', () {
    final sittings = [sat(20, 22, 10), sat(21, 1, 10)];
    expect(eveningsLeft(pagesLeft: 40, sittings: sittings), 2);
  });

  test('an evening that went backwards adds no pages', () {
    final sittings = [sat(18, 21, 20), sat(19, 21, -5)];
    // 20 pages over 2 evenings: 10 an evening.
    expect(eveningsLeft(pagesLeft: 30, sittings: sittings), 3);
  });

  test('nothing left means no estimate', () {
    expect(eveningsLeft(pagesLeft: 0, sittings: [sat(20, 21, 10)]), isNull);
  });

  test('a few pages left is still at least one evening', () {
    expect(eveningsLeft(pagesLeft: 1, sittings: [sat(20, 21, 50)]), 1);
  });

  group('time per page', () {
    PaceSitting read(int minutes, int pages) => (
      startedAt: DateTime(2026, 10, 20, 21),
      reading: Duration(minutes: minutes),
      pages: pages,
    );

    test('is unknown before any pages were read', () {
      expect(timePerPage(const []), isNull);
      expect(timePerPage([read(10, 0)]), isNull);
    });

    test('is all the reading over all the pages', () {
      expect(
        timePerPage([read(10, 20), read(20, 40)]),
        const Duration(seconds: 30),
      );
    });

    test('leaves out Sessions with no reading or no pages', () {
      expect(
        timePerPage([read(10, 20), read(0, 14), read(30, 0)]),
        const Duration(seconds: 30),
      );
    });
  });
}
