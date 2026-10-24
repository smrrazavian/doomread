import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/one_session.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/tasks/view_models/tasks_view_model.dart';
import 'package:doomread/ui/tasks/widgets/task_sheet.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Today's Tasks, each a small window that lights when it's Done, and the
/// dashed row to add one. A Task carried over from an earlier day looks
/// like any other: nothing here says "overdue".
class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => TasksViewModel(
      c.read<WorkRepository>(),
      c.read<SessionRepository>(),
      c.read<StopDeletedSessionsUseCase>(),
    ),
    child: const _Tasks(),
  );
}

class _Tasks extends StatelessWidget {
  const _Tasks();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();
    if (!vm.loaded) return const SizedBox.shrink();
    final next = vm.next;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in vm.tasks)
          Dismissible(
            key: ValueKey(task.id),
            onDismissed: (_) => _delete(context, vm, task),
            child: _TaskRow(task: task, next: task.id == next?.id),
          ),
        const SizedBox(height: 4),
        _AddRow(onTap: () => showTaskSheet(context, vm)),
      ],
    );
  }
}

/// Deletes [task] and offers to undo it, as the Library does.
void _delete(BuildContext context, TasksViewModel vm, Task task) {
  final l10n = AppLocalizations.of(context);
  unawaited(vm.delete(task));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.workDeleted(task.name)),
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(vm.restore(task)),
        ),
      ),
    );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.next});

  final Task task;

  /// The one to start next: its Start is filled, the others outlined.
  final bool next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.read<TasksViewModel>();
    final locale = Localizations.localeOf(context);
    final String? meta;
    if (task.doneAt case final at?) {
      final time = formatTime(at, locale);
      final minutes = vm.inOneGo(task).inMinutes;
      meta = minutes > 0
          ? l10n.taskDoneAt(time, minutes)
          : l10n.taskDoneAtOnly(time);
    } else if (task.estimate case final e?) {
      meta = l10n.taskAbout(e.inMinutes);
    } else {
      meta = null;
    }
    final start = Text(l10n.startWork(WorkKind.task.name));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          TaskWindow(lit: task.done),
          const SizedBox(width: 14),
          Expanded(
            // The name opens it for changes: its name, day and estimate.
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showTaskSheet(context, vm, editing: task),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      task.name,
                      style: text.titleMedium?.copyWith(
                        color: task.done ? Palette.soft : Palette.paper,
                      ),
                    ),
                    if (meta != null)
                      Text(
                        meta,
                        style: text.bodySmall?.copyWith(color: Palette.mute),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!task.done) ...[
            const SizedBox(width: 12),
            if (next)
              FilledButton(onPressed: () => _start(context, task), child: start)
            else
              OutlinedButton(
                onPressed: () => _start(context, task),
                child: start,
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> _start(BuildContext context, Task task) async {
  final vm = context.read<TasksViewModel>();
  if (!await stopOtherSessionFirst(context, task.id)) return;
  if (!context.mounted) return;
  await vm.start.execute(task.id);
  if (!context.mounted) return;
  if (vm.start.result case Ok(:final value)) {
    unawaited(HapticFeedback.lightImpact());
    await context.push('/reading/$value');
  }
}

/// A Task's window: dark until it's Done, then lit in lamplight.
class TaskWindow extends StatelessWidget {
  const TaskWindow({required this.lit, this.size = 22, super.key});

  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: lit ? l10n.taskDone : l10n.taskNotDone,
      child: Container(
        width: size * 0.82,
        height: size,
        decoration: BoxDecoration(
          color: lit ? Palette.lamp : Palette.unlit,
          border: Border.all(color: lit ? Palette.me : Palette.line),
          borderRadius: BorderRadius.circular(3),
          boxShadow: lit
              ? [
                  BoxShadow(
                    color: Palette.lamp.withValues(alpha: 0.45),
                    blurRadius: size * 0.6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// "Add a task", in a dashed outline: a place for one more.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: const _DashedOutline(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: Palette.mute),
                const SizedBox(width: 10),
                Text(
                  l10n.taskAdd,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Palette.mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedOutline extends CustomPainter {
  const _DashedOutline();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.7),
          const Radius.circular(12),
        ),
      );
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline oldDelegate) => false;
}
