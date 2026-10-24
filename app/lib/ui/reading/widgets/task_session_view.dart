import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/planned_break/widgets/next_break_card.dart';
import 'package:doomread/ui/reading/view_models/reading_view_model.dart';
import 'package:doomread/ui/reading/widgets/desk_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A Task's Session: the same Session as a book's, at a desk at night
/// instead of the House. The big clock is the pause button, the Aim card
/// fills toward the Aim for working, and the way out is Stop for now, or
/// Done.
class TaskSessionView extends StatelessWidget {
  const TaskSessionView({
    required this.record,
    required this.onStop,
    required this.onDone,
    super.key,
  });

  final SessionRecord record;

  /// Ends the Session; the Task stays undone, and nothing is asked.
  final VoidCallback onStop;

  /// Ends the Session and marks the Task Done.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ReadingViewModel>();
    final running = vm.session?.current != null;
    return Scaffold(
      // Back to Today leaves the Session running; Today offers it again.
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.taskWorkingOn,
                style: text.bodySmall?.copyWith(color: Palette.mute),
              ),
              Text(
                record.road.work.title,
                style: text.titleLarge?.copyWith(
                  fontFamily: bookFamily(context),
                ),
              ),
              const SizedBox(height: 16),
              _Clock(running: running),
              const SizedBox(height: 4),
              Text(
                running ? l10n.taskClockRunning : l10n.taskClockPaused,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: Palette.mute),
              ),
              const SizedBox(height: 20),
              const _AimCard(),
              const SizedBox(height: 8),
              NextBreakCard(sessionId: record.id),
              const Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: DeskView(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onStop,
                      child: Text(l10n.taskStop),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onDone,
                      child: Text(l10n.taskDone),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The time in one go, big; a tap pauses it, and paused, it goes quiet
/// until a tap keeps it going.
class _Clock extends StatelessWidget {
  const _Clock({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final vm = context.watch<ReadingViewModel>();
    return Semantics(
      button: true,
      label: running ? l10n.taskPause : l10n.taskResume,
      excludeSemantics: true,
      child: InkWell(
        key: const Key('taskClock'),
        borderRadius: BorderRadius.circular(24),
        onTap: running ? vm.pause.execute : vm.resume.execute,
        child: Text(
          formatClock(vm.shown, locale),
          textAlign: TextAlign.center,
          // Clocks don't mirror in Persian.
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontSize: locale.languageCode == 'fa' ? 68 : 72,
            height: 1.1,
            color: running ? Palette.paper : Palette.mute,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// "Aim: 25 min of work in one go", and a bar that fills toward it.
class _AimCard extends StatelessWidget {
  const _AimCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ReadingViewModel>();
    final aim = vm.aim;
    final shown = vm.shown;
    final beaten = shown >= aim;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.panel,
        border: Border.all(color: Palette.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.taskAim(aim.inMinutes),
                    style: text.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  beaten
                      ? l10n.taskAimBeaten
                      : l10n.taskAimToGo(minutesUp(aim - shown)),
                  style: text.bodySmall?.copyWith(color: Palette.me),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: beaten ? 1 : shown.inSeconds / aim.inSeconds,
                minHeight: 6,
                color: Palette.lamp,
                backgroundColor: Palette.line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
