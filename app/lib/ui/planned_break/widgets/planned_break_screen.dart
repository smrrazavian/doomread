import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/planned_break/break_text.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The Planned break: it's earned, its timer, and the return time named
/// before it starts. Offered here first, then running, then over.
class PlannedBreakScreen extends StatelessWidget {
  const PlannedBreakScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) =>
        PlannedBreakViewModel(c.read<SessionRepository>(), sessionId),
    child: const _PlannedBreak(),
  );
}

class _PlannedBreak extends StatelessWidget {
  const _PlannedBreak();

  /// Runs [command], then goes back to Reading.
  Future<void> _thenRead(
    BuildContext context,
    Future<void> Function() command,
    String id,
  ) async {
    await command();
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/reading/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final vm = context.watch<PlannedBreakViewModel>();
    final record = vm.record;
    final session = vm.session;
    final offer = vm.offer;
    if (record == null || session == null || offer == null) {
      return const Scaffold();
    }

    final work = record.road.work;
    final checkpoint = offer.checkpoint;
    final done = checkpointDone(l10n, work, checkpoint);
    final minutes = offer.length.inMinutes;
    final on = session.onBreak;
    final over = on && vm.left == Duration.zero;
    final at = formatTime(vm.endsAt, locale);

    final String heading;
    final String sub;
    if (over) {
      heading = say(context, Moment.breakOver);
      sub = waitingAfter(l10n, work, checkpoint);
    } else {
      heading = on ? l10n.onBreak : l10n.breakHere;
      sub = say(context, Moment.breakHere, {
        'minutes': formatNumber(minutes, locale),
      });
    }

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (done != null) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _Chip(done),
                ),
                const SizedBox(height: 12),
              ],
              Text(heading, style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(sub, style: text.bodyMedium),
              const SizedBox(height: 32),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  formatClock(on ? vm.left : offer.length, locale),
                  // Clocks don't mirror in Persian.
                  textDirection: TextDirection.ltr,
                  style: text.headlineSmall!.copyWith(
                    fontSize: locale.languageCode == 'fa' ? 68 : 72,
                    height: 1.1,
                    color: over ? Palette.mute : Palette.paper,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                backAt(l10n, work, checkpoint, at),
                style: text.bodySmall?.copyWith(color: Palette.mute),
              ),
              const SizedBox(height: 24),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.panel,
                  border: Border.all(color: Palette.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.bestTonight(session.longestStretch.inMinutes),
                    style: text.bodySmall,
                  ),
                ),
              ),
              const Spacer(),
              if (on)
                FilledButton(
                  onPressed: () =>
                      _thenRead(context, vm.back.execute, record.id),
                  child: Text(
                    over ? l10n.backToWork(work.kind.name) : l10n.imBack,
                  ),
                )
              else ...[
                FilledButton(
                  onPressed: vm.take.execute,
                  child: Text(l10n.startMyBreak(minutes)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      _thenRead(context, vm.nudge.execute, record.id),
                  child: Text(
                    work.kind.watched ? l10n.keepGoing : l10n.keepReading,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Palette.lamp),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Palette.lamp),
      ),
    ),
  );
}
