import 'package:doomread_core/src/pace.dart';
import 'package:doomread_core/src/road.dart';
import 'package:doomread_core/src/session.dart';
import 'package:doomread_core/src/session.dart' as core show longestStretch;
import 'package:doomread_core/src/work.dart';

/// One Session spent on a Work: the page it ended on (null until End of the
/// evening) and the Note written then.
typedef Sitting = ({Session session, int? toPage, String note});

/// Reaching the end of a Work, with what it took to get there.
class Finish {
  Finish._({
    required this.work,
    required this.at,
    required this.evenings,
    required this.longestStretch,
    required this.notes,
  });

  /// The Finish of [road]'s Work, worked out from the [sittings] spent on it;
  /// null while the Position is short of the end. Nothing about it is stored:
  /// it follows from the Position alone.
  static Finish? of(Road road, Iterable<Sitting> sittings) {
    if (!road.finished) return null;
    final ended = sittings.where((s) => s.toPage != null).toList();
    DateTime? at;
    for (final s in ended) {
      final start = s.session.startedAt;
      if (start == null || s.toPage! < road.work.totalPages) continue;
      if (at == null || start.isBefore(at)) at = start;
    }
    return Finish._(
      work: road.work,
      at: at,
      evenings: eveningsSpent([for (final s in ended) ?s.session.startedAt]),
      longestStretch: core.longestStretch(sittings.map((s) => s.session)),
      notes: sittings.where((s) => s.note.trim().isNotEmpty).length,
    );
  }

  final Work work;

  /// When the Session that reached the last page started; null if the
  /// Position got there some other way, say the Work was edited shorter.
  final DateTime? at;

  /// The evenings spent on it, counted the way the pace counts them.
  final int evenings;

  /// The longest Stretch the user read this Work in.
  final Duration longestStretch;

  /// How many Notes the user wrote along the way; empty ones don't count.
  final int notes;

  int get pages => work.totalPages;
}

/// [finishes] with the most recent first; ones with no time go last.
List<Finish> newestFirst(Iterable<Finish> finishes) =>
    finishes.toList()..sort((a, b) {
      final (x, y) = (a.at, b.at);
      if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
      return y.compareTo(x);
    });
