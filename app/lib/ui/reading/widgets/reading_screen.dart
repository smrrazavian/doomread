import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/evening/widgets/evening_screen.dart';
import 'package:doomread/ui/planned_break/widgets/next_break_card.dart';
import 'package:doomread/ui/reading/view_models/reading_view_model.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread/ui/reading/widgets/work_app_card.dart';
import 'package:doomread/ui/tour/view_models/tour_view_model.dart';
import 'package:doomread/ui/tour/widgets/hint_card.dart';
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

  /// Stops the Session for End of the evening; [finishing] when the user
  /// said "I finished it!", so the page there starts at the end.
  Future<void> _stop(
    BuildContext context,
    ReadingViewModel vm, {
    bool finishing = false,
  }) async {
    await vm.stop.execute();
    if (context.mounted && vm.stop.completed) {
      context.pushReplacement(eveningPath(vm.id, finishing: finishing));
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
        note: const _UrgeNote(),
      );
    }
    // The tour's demo: the real screen, but its buttons only close it.
    if (vm.demo) {
      return UrgeView(
        record: record,
        house: vm.house,
        app: 'Instagram',
        onBack: () => _endDemo(context, vm),
        onOpen: () => _endDemo(context, vm),
        note: const _UrgeNote(demo: true),
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
              _Guide(aim: aim),
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
                    backOn: vm.letPassed,
                    onBackOn: vm.backOnShown,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Near the end, "I finished it!" goes to End of the evening
              // with the page at the end, for the Note and then the Finish.
              if (record.road.nearEnd)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: vm.stop.running
                        ? null
                        : () => _stop(context, vm, finishing: true),
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

/// Out of the demo Urge, which leaves nothing behind.
void _endDemo(BuildContext context, ReadingViewModel vm) => vm.endDemo();

/// The first Session's guide under the Aim, one line at a time: the Aim,
/// then the offer of a demo Urge. Each waits for the last one's answer.
class _Guide extends StatelessWidget {
  const _Guide({required this.aim});

  final Duration aim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tour = context.watch<TourViewModel>();
    final Widget card;
    if (tour.shows(Hint.aim)) {
      card = HintCard(
        text: l10n.tourAimHint(aim.inMinutes),
        onGotIt: () => tour.seen(Hint.aim),
      );
    } else if (tour.shows(Hint.demoUrge) &&
        context.read<AppWatch>().available) {
      card = HintCard(
        text: l10n.tourDemoAsk,
        actions: [
          TextButton(
            key: const Key('demoNotNow'),
            onPressed: () => tour.seen(Hint.demoUrge),
            child: Text(l10n.tourNotNow),
          ),
          TextButton(
            key: const Key('demoShow'),
            onPressed: () {
              unawaited(tour.seen(Hint.demoUrge));
              context.read<ReadingViewModel>().showDemo();
            },
            child: Text(l10n.tourDemoShow),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.only(top: 16), child: card);
  }
}

/// Over the "not yet" screen: in the demo, that it is one, and the first
/// time it shows, the tour's line about it.
class _UrgeNote extends StatelessWidget {
  const _UrgeNote({this.demo = false});

  final bool demo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tour = context.watch<TourViewModel>();
    final hint = tour.shows(Hint.urge);
    if (!demo && !hint) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (demo)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.lamp),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    l10n.tourDemoBadge,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: Palette.lamp),
                  ),
                ),
              ),
            ),
          if (demo && hint) const SizedBox(height: 12),
          if (hint)
            HintCard(
              text: l10n.tourUrgeHint,
              onGotIt: () => tour.seen(Hint.urge),
            ),
        ],
      ),
    );
  }
}
