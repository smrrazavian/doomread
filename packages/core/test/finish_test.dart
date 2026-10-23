import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  final book = Work(
    id: 'w1',
    title: 'The Remains of the Day',
    author: 'Kazuo Ishiguro',
    totalPages: 245,
    checkpoints: const [],
  );

  /// A Session at 21:00 on [day] October, read for [minutes] in one go and
  /// ended at [toPage] with [note].
  Sitting sat(int day, int minutes, int? toPage, [String note = '']) {
    final start = DateTime(2026, 10, day, 21);
    final session = Session.fromEvents([
      SessionEvent(SessionEventKind.start, start),
      SessionEvent(
        SessionEventKind.stop,
        start.add(Duration(minutes: minutes)),
      ),
    ], now: start.add(const Duration(hours: 1)));
    return (session: session, toPage: toPage, note: note);
  }

  test('the Road is finished once the Position reaches the last page', () {
    expect(Road(book, position: 244).finished, isFalse);
    expect(Road(book, position: 245).finished, isTrue);
  });

  test('no Finish while the Position is short of the end', () {
    expect(Finish.of(Road(book, position: 244), [sat(20, 5, 244)]), isNull);
  });

  test('a Finish counts pages, evenings, the Longest stretch and Notes', () {
    final finish = Finish.of(Road(book, position: 245), [
      sat(18, 5, 100, 'Stevens sets off.'),
      sat(19, 18, 200, '  '),
      sat(19, 7, 230, 'The car breaks down.'),
      sat(21, 9, 245, 'He misses Miss Kenton.'),
    ])!;
    expect(finish.pages, 245);
    expect(finish.evenings, 3);
    expect(finish.longestStretch, const Duration(minutes: 18));
    expect(finish.notes, 3, reason: 'a blank Note is not a Note');
    expect(finish.at, DateTime(2026, 10, 21, 21));
  });

  test('a Session never ended on End of the evening is not an evening', () {
    final finish = Finish.of(Road(book, position: 245), [
      sat(18, 5, 245),
      sat(20, 5, null),
    ])!;
    expect(finish.evenings, 1);
  });

  test('a Work edited shorter than its Position is finished, untimed', () {
    final finish = Finish.of(Road(book, position: 300), [sat(18, 5, 200)])!;
    expect(finish.at, isNull);
  });

  test('the most recent Finish comes first, untimed ones last', () {
    Finish at(int day) =>
        Finish.of(Road(book, position: 245), [sat(day, 5, 245)])!;
    final untimed = Finish.of(Road(book, position: 245), const [])!;
    expect(newestFirst([at(3), untimed, at(9), at(5)]).map((f) => f.at?.day), [
      9,
      5,
      3,
      null,
    ]);
  });
}
