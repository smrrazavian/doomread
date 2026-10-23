import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/books/view_models/work_form_view_model.dart';
import 'package:doomread/ui/core/number_format.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefill numbers in the user's digits, once the locale is known.
    final editing = widget.editing;
    if (_prefilled || editing == null) return;
    _prefilled = true;
    final locale = Localizations.localeOf(context);
    _pages.text = formatNumber(editing.totalPages, locale);
    _checkpoints.text = formatNumbers(editing.checkpoints, locale);
  }

  @override
  void dispose() {
    for (final c in [_title, _author, _pages, _checkpoints]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(WorkFormViewModel vm) async {
    await vm.save.execute(
      WorkDraft(
        title: _title.text,
        author: _author.text,
        totalPages: parseNumber(_pages.text) ?? 0,
        // Unreadable chapter ends count as out of range, so the user is told.
        checkpoints: parseNumbers(_checkpoints.text) ?? const [-1],
      ),
    );
    if (mounted && vm.save.result is Ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<WorkFormViewModel>();
    String? problem(WorkProblem p, String message) =>
        vm.problems.contains(p) ? message : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editing == null ? l10n.tonightAddBook : l10n.editBook,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
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
            decoration: InputDecoration(labelText: l10n.fieldAuthor),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('pages'),
            controller: _pages,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.fieldPages,
              errorText: problem(WorkProblem.noPages, l10n.problemNoPages),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('checkpoints'),
            controller: _checkpoints,
            decoration: InputDecoration(
              labelText: l10n.fieldCheckpoints,
              hintText: l10n.fieldCheckpointsHint,
              errorText: problem(
                WorkProblem.checkpointPastEnd,
                l10n.problemCheckpointPastEnd,
              ),
            ),
          ),
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
