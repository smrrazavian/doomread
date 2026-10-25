import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/books/view_models/work_form_view_model.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Add a Work, or edit it when [editing] is given.
class WorkFormScreen extends StatelessWidget {
  const WorkFormScreen({this.editing, super.key});

  final Work? editing;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) =>
        WorkFormViewModel(c.read<WorkRepository>(), editing: editing),
    child: _WorkForm(editing: editing),
  );
}

class _WorkForm extends StatefulWidget {
  const _WorkForm({required this.editing});

  final Work? editing;

  @override
  State<_WorkForm> createState() => _WorkFormState();
}

class _WorkFormState extends State<_WorkForm> {
  late final _title = TextEditingController(text: widget.editing?.title);
  late final _author = TextEditingController(text: widget.editing?.author);
  final _pages = TextEditingController();
  final _checkpoints = TextEditingController();
  var _prefilled = false;

  /// Chosen when adding; an existing Work keeps its kind, since its Position
  /// is already in that kind's unit.
  late WorkKind _kind = widget.editing?.kind ?? WorkKind.paperBook;
  bool get _timed => _kind.unit == WorkUnit.second;

  /// About how many chapters a book has, asked instead of the pages they
  /// end on: its Checkpoints are spread evenly, and each Chapter done
  /// replaces an estimate with the real page.
  late int _chapters = widget.editing == null
      ? 10
      : widget.editing!.checkpoints.length + 1;

  /// Whether the exact pages are asked instead of the count: on "Edit
  /// pages", or for a Work whose Checkpoints were all typed.
  late bool _exact =
      widget.editing != null &&
      widget.editing!.estimated == 0 &&
      widget.editing!.checkpoints.isNotEmpty;

  /// The pages shown as estimates in the exact list: the Work's own, or
  /// those "Edit pages" spread. Left as they are, they stay estimates.
  late List<int> _estimates = widget.editing == null
      ? const []
      : widget.editing!.checkpoints
            .skip(
              widget.editing!.checkpoints.length - widget.editing!.estimated,
            )
            .toList();

  /// Only a book's chapters are counted; a timestamp is on the player, and
  /// a series' Checkpoints are its episodes.
  bool get _counting => _kind.unit == WorkUnit.page && !_exact;

  /// Shows the pages the count would put chapters on, to change.
  void _editPages() {
    if (_checkpoints.text.trim().isEmpty) {
      final (:checkpoints, :estimated) = spreadCheckpoints(
        parseNumber(_pages.text) ?? 0,
        _chapters,
        known: WorkFormViewModel.known(widget.editing),
      );
      _checkpoints.text = formatNumbers(
        checkpoints,
        Localizations.localeOf(context),
      );
      _estimates = checkpoints.skip(checkpoints.length - estimated).toList();
    }
    setState(() => _exact = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefill numbers in the user's digits, once the locale is known.
    final editing = widget.editing;
    if (_prefilled || editing == null) return;
    _prefilled = true;
    final locale = Localizations.localeOf(context);
    if (_timed) {
      _pages.text = formatClock(Duration(seconds: editing.totalPages), locale);
      _checkpoints.text = formatClocks(editing.checkpoints, locale);
    } else {
      _pages.text = formatNumber(editing.totalPages, locale);
      _checkpoints.text = formatNumbers(editing.checkpoints, locale);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _author, _pages, _checkpoints]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(WorkFormViewModel vm) async {
    await vm.saveTyped(
      title: _title.text,
      author: _author.text,
      length: _pages.text,
      checkpoints: _checkpoints.text,
      kind: _kind,
      chapters: _counting ? _chapters : null,
      estimates: _estimates,
    );
    if (mounted && vm.save.result is Ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final vm = context.watch<WorkFormViewModel>();
    String? problem(WorkProblem p, String message) =>
        vm.problems.contains(p) ? message : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editing == null ? l10n.tonightAddBook : l10n.editBook,
        ),
        actions: [
          // The Library deletes it, so Undo shows there.
          if (widget.editing != null)
            IconButton(
              tooltip: l10n.deleteWork,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context.pop(true),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.editing == null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in WorkKind.media)
                  ChoiceChip(
                    key: Key(kind.name),
                    avatar: Icon(kindIcon(kind)),
                    label: Text(kindName(l10n, kind)),
                    showCheckmark: false,
                    selected: kind == _kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            key: const Key('title'),
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.fieldTitle,
              errorText: problem(WorkProblem.noTitle, l10n.problemNoTitle),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('author'),
            controller: _author,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _kind.watched ? l10n.fieldCreator : l10n.fieldAuthor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('pages'),
            controller: _pages,
            keyboardType: _timed
                ? TextInputType.datetime
                : TextInputType.number,
            // Timestamps read like a clock, which never mirrors.
            textDirection: _timed ? TextDirection.ltr : null,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: switch (_kind.unit) {
                WorkUnit.page => l10n.fieldPages,
                WorkUnit.episode => l10n.fieldEpisodes,
                WorkUnit.second => l10n.fieldDuration,
              },
              hintText: _timed ? l10n.fieldDurationHint : null,
              errorText: problem(WorkProblem.noPages, switch (_kind.unit) {
                WorkUnit.page => l10n.problemNoPages,
                WorkUnit.episode => l10n.problemNoEpisodes,
                WorkUnit.second => l10n.problemNoDuration,
              }),
            ),
          ),
          if (_counting) ...[
            const SizedBox(height: 24),
            Text(l10n.fieldChapters, style: text.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  key: const Key('fewerChapters'),
                  tooltip: l10n.fewerChapters,
                  onPressed: _chapters > 1
                      ? () => setState(() => _chapters--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    formatNumber(_chapters, locale),
                    key: const Key('chapters'),
                    textAlign: TextAlign.center,
                    style: text.headlineSmall,
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('moreChapters'),
                  tooltip: l10n.moreChapters,
                  onPressed: _chapters < 999
                      ? () => setState(() => _chapters++)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.fieldChaptersHint,
              style: text.bodySmall?.copyWith(color: Palette.mute),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _editPages,
                child: Text(l10n.editChapterPages),
              ),
            ),
          ]
          // A series' Checkpoints are its episodes, so there's nothing to ask.
          else if (_kind != WorkKind.series) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('checkpoints'),
              controller: _checkpoints,
              keyboardType: _timed ? TextInputType.datetime : null,
              textDirection: _timed ? TextDirection.ltr : null,
              decoration: InputDecoration(
                labelText: _timed
                    ? l10n.fieldTimestamps
                    : l10n.fieldCheckpoints,
                hintText: _timed
                    ? l10n.fieldTimestampsHint
                    : l10n.fieldCheckpointsHint,
                errorText:
                    problem(
                      WorkProblem.checkpointsUnreadable,
                      _timed
                          ? l10n.checkpointsFormatTimestamps
                          : l10n.checkpointsFormatPages,
                    ) ??
                    problem(
                      WorkProblem.checkpointPastEnd,
                      _timed
                          ? l10n.problemTimestampPastEnd
                          : l10n.problemCheckpointPastEnd,
                    ),
              ),
            ),
            if (!_timed)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => setState(() => _exact = false),
                  child: Text(l10n.useChapterCount),
                ),
              ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: vm.save.running ? null : () => _save(vm),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
