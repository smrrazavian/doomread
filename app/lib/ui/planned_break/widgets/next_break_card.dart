import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/planned_break/break_text.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
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
      line = breakLine(
        l10n,
        locale,
        record.road.work,
        offer.checkpoint,
        minutes,
      );
      actions = [
        if (vm.due) ...[
          TextButton(onPressed: vm.nudge.execute, child: Text(l10n.nudgeBreak)),
          TextButton(
            onPressed: () => context.push('/break/${vm.id}'),
            child: Text(l10n.takeBreak),
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
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions)
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
