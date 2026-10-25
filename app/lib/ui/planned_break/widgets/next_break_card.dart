import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/planned_break/break_text.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
import 'package:doomread/ui/planned_break/widgets/chapter_end_dialog.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// On Reading: how far away the next Planned break is. Once it's due, the
/// user takes it or nudges it later; they never plan one themselves.
class NextBreakCard extends StatelessWidget {
  const NextBreakCard({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) =>
        PlannedBreakViewModel(c.read<SessionRepository>(), sessionId),
    child: const _Card(),
  );
}

class _Card extends StatelessWidget {
  const _Card();

  Future<void> _markDone(BuildContext context, PlannedBreakViewModel vm) async {
    final next = vm.markable;
    if (next == null) return;
    int? page;
    if (vm.markableEstimated) {
      final road = vm.record!.road;
      page = await askChapterEnd(
        context,
        chapter: chapterEndingAt(road.work, next),
        estimate: next,
        after: road.position,
        before: road.work.totalPages,
      );
      if (page == null) return;
    }
    await vm.markDone.execute(page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<PlannedBreakViewModel>();
    final record = vm.record;
    final session = vm.session;
    final offer = vm.offer;
    if (record == null || session == null || session.stopped || offer == null) {
      return const SizedBox.shrink();
    }
    final minutes = minutesUp(vm.toGo);

    final String line;
    final List<Widget> actions;
    if (session.onBreak) {
      line = l10n.onBreakUntil(formatTime(vm.endsAt, locale));
      actions = [
        TextButton(
          onPressed: () => context.push('/break/${vm.id}'),
          child: Text(l10n.showBreak),
        ),
      ];
    } else {
      final work = record.road.work;
      line = breakLine(
        l10n,
        locale,
        work,
        offer,
        minutes: minutes,
        read: session.readingSinceBreak.inMinutes,
      );
      actions = [
        // "Chapter done": the break comes due at the Checkpoint itself. An
        // estimate asks first where the chapter really ended.
        if (checkpointDone(l10n, work, vm.markable) case final label?)
          TextButton(
            onPressed: vm.markDone.running
                ? null
                : () => _markDone(context, vm),
            child: Text(label),
          ),
        if (vm.due) ...[
          TextButton(onPressed: vm.nudge.execute, child: Text(l10n.nudgeBreak)),
          FilledButton(
            onPressed: () async {
              await vm.take.execute();
              if (context.mounted) unawaited(context.push('/break/${vm.id}'));
            },
            child: Text(l10n.breakCardStart(offer.length.inMinutes)),
          ),
        ],
      ];
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.panel,
        border: Border.all(color: Palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.local_cafe_outlined, color: Palette.lamp),
                const SizedBox(width: 12),
                Expanded(child: Text(line, style: text.bodySmall)),
              ],
            ),
            if (actions.isNotEmpty)
              // "Chapter done" makes three; they wrap rather than overflow.
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
