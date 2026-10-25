import 'package:doomread_core/src/work.dart';

/// What the user typed for a Work before it's saved. The numbers are in the
/// [kind]'s unit, as on [Work].
class WorkDraft {
  WorkDraft({
    required this.title,
    required this.author,
    required this.totalPages,
    required this.checkpoints,
    this.kind = WorkKind.paperBook,
    this.checkpointsUnreadable = false,
    this.chapters,
    this.estimates = const [],
  });

  final String title;
  final String author;
  final WorkKind kind;
  final int totalPages;

  /// Ignored for a series, whose Checkpoints are its episodes. With
  /// [chapters], the known ones are kept as they are.
  final List<int> checkpoints;

  /// About how many chapters, when the user gave a count instead of the
  /// pages. Only a Work in pages takes one.
  final int? chapters;

  /// The pages shown as estimates in a typed list: those still at the end
  /// of [checkpoints] stay estimates, so Chapter done still asks for them.
  final List<int> estimates;

  bool get _counted => chapters != null && kind.unit == WorkUnit.page;

  /// How many of [checkpoints] at its end are [estimates] left unchanged.
  int get _trailingEstimates =>
      checkpoints.reversed.takeWhile(estimates.contains).length;

  /// The Checkpoints to save. Typed ones are known, but for [estimates]
  /// left unchanged at the end; with a chapter count, the rest after the
  /// known ones are spread evenly as estimates.
  Checkpoints get toSave => _counted
      ? spreadCheckpoints(
          totalPages,
          chapters!,
          known: checkpoints
              .take(checkpoints.length - _trailingEstimates)
              .toList(),
        )
      : (checkpoints: checkpoints, estimated: _trailingEstimates);

  /// The user typed Checkpoints that couldn't be read; [checkpoints] is moot.
  final bool checkpointsUnreadable;

  /// Everything wrong with this draft; empty when it can be saved.
  Set<WorkProblem> get problems => {
    if (title.trim().isEmpty) WorkProblem.noTitle,
    if (totalPages < 1) WorkProblem.noPages,
    if (checkpointsUnreadable && kind != WorkKind.series && !_counted)
      WorkProblem.checkpointsUnreadable,
    // Only once the length is valid; otherwise one mistake shows twice.
    if (totalPages >= 1 &&
        !checkpointsUnreadable &&
        kind != WorkKind.series &&
        !_counted &&
        checkpoints.any((c) => c < 1 || c > totalPages))
      WorkProblem.checkpointPastEnd,
  };
}

/// [noPages] means no length, in whatever unit the Work counts.
enum WorkProblem { noTitle, noPages, checkpointsUnreadable, checkpointPastEnd }
