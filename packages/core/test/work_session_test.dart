import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  final evening = DateTime(2026, 10, 22, 21);

  Work work(String id, {WorkKind kind = WorkKind.paperBook}) => Work(
    id: id,
    title: id,
    author: '',
    totalPages: kind == WorkKind.series ? 10 : 412,
    checkpoints: const [],
    kind: kind,
  );

  /// A Session on [w] that started at [start] and ran [length] unbroken,
  /// stopped unless [length] is zero, and moved the Position [pages].
  WorkSession sat(
    Work w,
    DateTime start,
    Duration length, {
    ({int from, int to})? pages,
  }) => (
    road: Road(w, position: pages?.to ?? 0),
    session: Session.fromEvents([
      SessionEvent(SessionEventKind.start, start),
      if (length > Duration.zero)
        SessionEvent(SessionEventKind.stop, start.add(length)),
    ], now: evening),
    pages: pages,
  );

  final book = work('b');
  final ebook = work('e', kind: WorkKind.ebook);
  final dark = work('d', kind: WorkKind.series);
  final yesterday = evening.subtract(const Duration(days: 1));

  test('reading and watching keep their Longest stretch apart', () {
    final all = [
      sat(book, yesterday, const Duration(minutes: 6)),
      sat(dark, yesterday, const Duration(minutes: 40)),
    ];
    expect(
      longestStretch(alike(all, Attention.reading)),
      const Duration(minutes: 6),
    );
    expect(
      longestStretch(alike(all, Attention.watching)),
      const Duration(minutes: 40),
    );
  });

  test("tonight's Aim is the Longest stretch of its kind, plus a minute", () {
    final before = [
      sat(book, yesterday, const Duration(minutes: 6)),
      sat(ebook, yesterday, const Duration(minutes: 9)),
      sat(dark, yesterday, const Duration(minutes: 40)),
    ];
    expect(aimAfter(before, Attention.reading), const Duration(minutes: 10));
    expect(aimAfter(before, Attention.watching), const Duration(minutes: 41));
    expect(aimAfter(const [], Attention.reading), const Duration(minutes: 1));
  });

  test("a Work's sittings are its ended Sessions, with their reading", () {
    final history = [
      sat(
        book,
        yesterday,
        const Duration(minutes: 30),
        pages: (from: 0, to: 20),
      ),
      sat(book, evening, const Duration(minutes: 5)),
      sat(
        ebook,
        yesterday,
        const Duration(minutes: 9),
        pages: (from: 0, to: 9),
      ),
    ];
    expect(sittingsOf(book, history), [
      (startedAt: yesterday, reading: const Duration(minutes: 30), pages: 20),
    ]);
  });

  test('evenings left go by the pace of this Work alone', () {
    final history = [
      sat(
        book,
        yesterday,
        const Duration(minutes: 30),
        pages: (from: 0, to: 20),
      ),
      sat(
        ebook,
        yesterday,
        const Duration(minutes: 9),
        pages: (from: 0, to: 1),
      ),
    ];
    // 20 pages an evening, 392 to go.
    expect(eveningsLeftOn(Road(book, position: 20), history), 20);
    expect(eveningsLeftOn(Road(book, position: 20), const []), isNull);
  });

  test("a long evening of reading doesn't stretch a series' break", () {
    final read = sat(book, yesterday, const Duration(minutes: 40));
    final tonight = sat(dark, evening, Duration.zero);

    // Reading's 40 minutes would ask for 24 minutes first; nothing has been
    // watched yet, so the series starts at the shortest interval.
    final offer = plannedBreakOf(tonight, before: [read]);
    expect(offer!.from, shortestInterval);
  });

  test("a Planned break goes by the pace in this Work's own sittings", () {
    final w = Work(
      id: 'w',
      title: 'Dune',
      author: '',
      totalPages: 412,
      checkpoints: const [30, 60],
    );
    // A page a minute here; another Work's pace doesn't count.
    final before = [
      sat(w, yesterday, const Duration(minutes: 20), pages: (from: 0, to: 20)),
      sat(
        book,
        yesterday,
        const Duration(minutes: 1),
        pages: (from: 0, to: 100),
      ),
    ];
    final tonight = sat(w, evening, Duration.zero);
    final offer = plannedBreakOf(tonight, before: before);
    expect(offer?.checkpoint, 30);
    expect(offer?.at, const Duration(minutes: 30));
  });

  test('the chapter a Checkpoint ends counts from 1', () {
    final w = Work(
      id: 'w',
      title: 'Dune',
      author: '',
      totalPages: 412,
      checkpoints: const [60, 30],
    );
    expect(chapterEndingAt(w, 30), 1);
    expect(chapterEndingAt(w, 60), 2);
  });
}
