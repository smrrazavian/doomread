import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// Adds a new Work, or edits [editing] when given.
class WorkFormViewModel extends ChangeNotifier {
  WorkFormViewModel(this._works, {this.editing}) {
    save = Command1(_save);
  }

  final WorkRepository _works;
  final Work? editing;

  /// Saves a draft; its result holds the Work's id.
  late final Command1<String, WorkDraft> save;

  /// Saves what the user typed: the length and Checkpoints in the [kind]'s
  /// unit (timestamps for a film or podcast), in either language's digits.
  /// With [chapters], a count stands in for the Checkpoints: they're spread
  /// evenly, after the ones already marked on the Work being edited.
  /// Without, [estimates] are the pages the list was shown as estimates.
  Future<void> saveTyped({
    required String title,
    required String length,
    required WorkKind kind,
    String author = '',
    String checkpoints = '',
    int? chapters,
    List<int> estimates = const [],
  }) {
    final timed = kind.unit == WorkUnit.second;
    final marks = chapters != null
        ? known(editing)
        : (timed ? parseClocks : parseNumbers)(checkpoints);
    return save.execute(
      WorkDraft(
        title: title,
        author: author,
        totalPages: (timed ? parseClock : parseNumber)(length) ?? 0,
        checkpoints: marks ?? const [],
        checkpointsUnreadable: marks == null,
        kind: kind,
        chapters: chapters,
        estimates: estimates,
      ),
    );
  }

  /// [work]'s Checkpoints that aren't estimates.
  static List<int> known(Work? work) => work == null
      ? const []
      : work.checkpoints
            .take(work.checkpoints.length - work.estimated)
            .toList();

  /// What's wrong with the last draft the user tried to save.
  Set<WorkProblem> get problems => _problems;
  Set<WorkProblem> _problems = const {};

  Future<Result<String>> _save(WorkDraft draft) async {
    _problems = draft.problems;
    notifyListeners();
    if (_problems.isNotEmpty) return Result.error(InvalidWork(_problems));
    final title = draft.title.trim();
    final (:checkpoints, :estimated) = draft.toSave;
    final author = draft.author.trim();
    final editing = this.editing;
    if (editing == null) {
      return Result.ok(
        await _works.add(
          title: title,
          author: author,
          totalPages: draft.totalPages,
          checkpoints: checkpoints,
          kind: draft.kind,
          estimated: estimated,
        ),
      );
    }
    await _works.edit(
      editing.id,
      title: title,
      author: author,
      totalPages: draft.totalPages,
      checkpoints: checkpoints,
      estimated: estimated,
    );
    return Result.ok(editing.id);
  }
}

class InvalidWork implements Exception {
  InvalidWork(this.problems);
  final Set<WorkProblem> problems;
}
