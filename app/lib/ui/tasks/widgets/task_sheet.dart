import 'dart:async';

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/tasks/view_models/tasks_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// Adds a Task, or changes [editing]: its name and the day it's for, and
/// when changing one, its estimate. Adding needs only a name.
Future<void> showTaskSheet(
  BuildContext context,
  TasksViewModel vm, {
  Task? editing,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Palette.panel,
  builder: (_) => _TaskSheet(vm: vm, editing: editing),
);

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({required this.vm, this.editing});

  final TasksViewModel vm;
  final Task? editing;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final _name = TextEditingController(text: widget.editing?.name);
  final _estimate = TextEditingController();
  late DateTime? _day = widget.editing == null
      ? widget.vm.today
      : widget.editing!.day;
  Set<TaskProblem> _problems = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.editing?.estimate case final e? when _estimate.text.isEmpty) {
      _estimate.text = formatNumber(
        e.inMinutes,
        Localizations.localeOf(context),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _estimate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final problems = TasksViewModel.problems(_name.text, _estimate.text);
    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      return;
    }
    final minutes = parseNumber(_estimate.text);
    final estimate = minutes == null || minutes == 0
        ? null
        : Duration(minutes: minutes);
    final navigator = Navigator.of(context);
    if (widget.editing case final task?) {
      await widget.vm.edit(
        task,
        name: _name.text,
        day: _day,
        estimate: estimate,
      );
    } else {
      await widget.vm.add(_name.text, day: _day);
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final editing = widget.editing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? l10n.taskEdit : l10n.taskNew,
                style: text.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('taskName'),
                controller: _name,
                autofocus: !editing,
                textInputAction: editing
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: editing ? null : (_) => unawaited(_save()),
                decoration: InputDecoration(
                  labelText: l10n.taskName,
                  errorText: _problems.contains(TaskProblem.noName)
                      ? l10n.taskNoName
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              _DayChips(
                today: widget.vm.today,
                day: _day,
                onChanged: (d) => setState(() => _day = d),
              ),
              if (editing) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('taskEstimate'),
                  controller: _estimate,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.taskEstimate,
                    errorText:
                        _problems.contains(TaskProblem.estimateUnreadable)
                        ? l10n.taskEstimateUnreadable
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(editing ? l10n.save : l10n.taskAddButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today, Tomorrow, or another day picked from the days ahead, named in
/// the user's calendar.
class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.today,
    required this.day,
    required this.onChanged,
  });

  final DateTime today;
  final DateTime? day;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final other = day != null && day != today && day != tomorrow;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.taskDayToday),
          selected: day == today,
          onSelected: (_) => onChanged(today),
        ),
        ChoiceChip(
          label: Text(l10n.taskDayTomorrow),
          selected: day == tomorrow,
          onSelected: (_) => onChanged(tomorrow),
        ),
        ChoiceChip(
          label: Text(other ? formatDayMonth(context, day!) : l10n.taskDayPick),
          selected: other,
          onSelected: (_) async {
            final picked = await _pickDay(context, today);
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}

/// The next eight weeks after tomorrow, one row per day: Solar Hijri in
/// Persian, Gregorian otherwise.
Future<DateTime?> _pickDay(BuildContext context, DateTime today) =>
    showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Palette.panel,
      builder: (context) => SafeArea(
        child: ListView(
          children: [
            for (var i = 2; i < 58; i++)
              if (DateTime(today.year, today.month, today.day + i) case final d)
                ListTile(
                  title: Text(formatWeekdayDayMonth(context, d)),
                  onTap: () => Navigator.pop(context, d),
                ),
          ],
        ),
      ),
    );
