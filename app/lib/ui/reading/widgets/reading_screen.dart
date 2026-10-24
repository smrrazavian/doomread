import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/planned_break/widgets/next_break_card.dart';
import 'package:doomread/ui/reading/view_models/reading_view_model.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread/ui/reading/widgets/work_app_card.dart';
import 'package:doomread/ui/urge/urge_watch.dart';
import 'package:doomread/ui/urge/widgets/urge_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The Reading screen: a quiet timer, the Aim, the House, Pause and Stop.
/// While an Urge is open it's the "not yet" screen, and after a Slip the
/// kind After-a-slip one, both straight from the journal.
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => ReadingViewModel(c.read<SessionRepository>(), sessionId),
    child: const _Reading(),
  );
}

class _Reading extends StatelessWidget {
  const _Reading();

  Future<void> _stop(BuildContext context, ReadingViewModel vm) async {
    await vm.stop.execute();
    if (context.mounted && vm.stop.completed) {
      context.pushReplacement('/evening/${vm.id}');
    }
  }

  Future<void> _finish(BuildContext context, ReadingViewModel vm) async {
    final work = vm.record!.road.work;
    await vm.finish.execute();
    if (context.mounted && vm.finish.completed) {
      context.go('/building/finish/${work.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final vm = context.watch<ReadingViewModel>();
    final record = vm.record;
    final session = vm.session;
    if (record == null || session == null) return const Scaffold();
    if (session.urgeOpen) {
      final urges = context.read<UrgeWatch>();
      return UrgeView(
        record: record,
        house: vm.house,
        app: urges.app?.label,
        onBack: vm.letPass.execute,
        onOpen: () => urges.slip(record),
      );
    }
    if (session.slipped) {
      return AfterSlipView(
        session: session,
        house: vm.house,
        kind: record.road.work.kind,
        onBackIn: vm.resume.execute,
        onDone: () => _stop(context, vm),
      );
    }

    final current = session.current;
    final aim = vm.aim;
    final String aimLine;
    if (current == null) {
      aimLine = l10n.paused;
    } else if (current.length >= aim) {
      aimLine = say(context, Moment.newBest);
    } else {
      aimLine =
          '${l10n.aim(aim.inMinutes)} '
          '${l10n.aimToGo(minutesUp(aim - current.length))}';
    }

    return Scaffold(
      // Back to Tonight leaves the Session running; Tonight offers it again.
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(record.road.work.title, style: text.bodySmall),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  formatClock(vm.shown, locale),
                  // Clocks don't mirror in Persian.
                  textDirection: TextDirection.ltr,
                  style: text.headlineSmall!.copyWith(
                    fontSize: locale.languageCode == 'fa' ? 68 : 72,
                    height: 1.1,
                    color: current == null ? Palette.mute : Palette.paper,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(aimLine, style: text.bodyMedium),
              const SizedBox(height: 24),
              NextBreakCard(sessionId: record.id),
              const SizedBox(height: 8),
              WorkAppCard(workId: record.road.work.id),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: HouseView(
                    windows: vm.house,
                    kind: record.road.work.kind,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Near the end, the Finish is one tap, as on End of the
              // evening.
              if (record.road.nearEnd)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: vm.finish.running
                        ? null
                        : () => _finish(context, vm),
                    child: Text(l10n.eveningFinished),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: current == null
                        ? OutlinedButton(
                            onPressed: vm.resume.execute,
                            child: Text(l10n.resume),
                          )
                        : OutlinedButton(
                            onPressed: vm.pause.execute,
                            child: Text(l10n.pause),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _stop(context, vm),
                      child: Text(l10n.stopForTonight),
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
