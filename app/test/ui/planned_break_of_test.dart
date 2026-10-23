import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final evening = DateTime(2026, 10, 22, 21);

  SessionRecord sitting(String id, Work work, DateTime start, Duration d) =>
      SessionRecord(
        id: id,
        road: Road(work, position: 0),
        events: [
          SessionEvent(SessionEventKind.start, start),
          if (d > Duration.zero)
            SessionEvent(SessionEventKind.stop, start.add(d)),
        ],
      );

  test("a long evening of reading doesn't stretch a series' break", () {
    final book = Work(
      id: 'b',
      title: 'Dune',
      author: '',
      totalPages: 412,
      checkpoints: const [],
    );
    final dark = Work(
      id: 'd',
      title: 'Dark',
      author: '',
      totalPages: 10,
      checkpoints: const [],
      kind: WorkKind.series,
    );
    final read = sitting(
      'r',
      book,
      evening.subtract(const Duration(days: 1)),
      const Duration(minutes: 40),
    );
    final tonight = sitting('t', dark, evening, Duration.zero);

    // Reading's 40 minutes would ask for 24 minutes first; nothing has been
    // watched yet, so the series starts at the shortest interval.
    final offer = plannedBreakOf(tonight, [read, tonight], evening);
    expect(offer!.from, shortestInterval);
  });
}
