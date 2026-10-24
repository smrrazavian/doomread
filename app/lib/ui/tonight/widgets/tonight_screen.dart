import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/data/services/session_notification.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/empty_scenes.dart';
import 'package:doomread/ui/core/road_view.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/reading/widgets/work_app_card.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/ui/tonight/view_models/tonight_view_model.dart';
import 'package:doomread/ui/tonight/widgets/yalda_tonight.dart';
import 'package:doomread/ui/tour/view_models/tour_view_model.dart';
import 'package:doomread/ui/watch/view_models/watch_ask_view_model.dart';
import 'package:doomread/ui/watch/widgets/watch_disclosure.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TonightScreen extends StatelessWidget {
  const TonightScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => TonightViewModel(
      c.read<WorkRepository>(),
      c.read<SessionRepository>(),
      c.read<SettingsRepository>(),
      c.read<SessionNotification>(),
    ),
    child: const _Tonight(),
  );
}

class _Tonight extends StatelessWidget {
  const _Tonight();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<TonightViewModel>();
    final tour = context.watch<TourViewModel>();
    final road = vm.road;
    // The first Work was just added in the intro: its Session starts now.
    if (road != null && tour.takeStart()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(_start(context, vm));
      });
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      // Scrolls only when the screen is too short to fit it all; otherwise
      // the Spacer keeps the week and the button down by the thumb.
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
              child: Column(
                // stretch so text hugs the start edge in both directions
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.navTonight, style: text.headlineSmall),
                  const SizedBox(height: 16),
                  if (road != null) ...[
                    _WorkCard(road: road, evenings: vm.evenings),
                    const SizedBox(height: 16),
                    Text(l10n.aim(vm.aim.inMinutes), style: text.bodyMedium),
                    // Only on Shab-e Yalda.
                    if (vm.yalda case final night?)
                      YaldaTonight(night: night, kind: road.work.kind),
                    const Spacer(),
                    _ReadingWeekStrip(
                      week: vm.readingWeek(
                        firstDayOfWeek(
                          Localizations.localeOf(context).languageCode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: vm.start.running
                          ? null
                          : () => _start(context, vm),
                      child: Text(
                        vm.openSession == null
                            ? l10n.startWork(road.work.kind.name)
                            : l10n.backToWork(road.work.kind.name),
                      ),
                    ),
                  ] else if (vm.loaded && tour.loaded && !tour.introDue) ...[
                    const EmptySceneView(EmptyScene.darkWindow),
                    const SizedBox(height: 16),
                    Text(l10n.emptyTonight, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(l10n.tonightEmpty, style: text.bodyMedium),
                    // A Work finished on Yalda still has its night.
                    if (vm.yalda case final night?) YaldaTonight(night: night),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton(
                        onPressed: () => context.push('/work/new'),
                        child: Text(l10n.tonightAddBook),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _start(BuildContext context, TonightViewModel vm) async {
  // Asked here, the moment the timer is about to matter, and never in the
  // way: the Session starts whatever the answer. One ask per tap at most;
  // the "not yet" screen waits for Reading or the next Start when the
  // notification took this one.
  final explain = await vm.shouldExplainNotification();
  if (!context.mounted) return;
  final watchAsk = context.read<WatchAskViewModel>();
  if (explain) {
    final allow = await showDialog<bool>(
      context: context,
      builder: (_) => const _NotificationExplainer(),
    );
    await vm.answerNotification(allow: allow ?? false);
    if (!context.mounted) return;
  } else if (watchAsk.due && !context.read<TourViewModel>().watchAskWaits) {
    await watchAsk.ask.execute(
      () async => context.mounted && await askToWatch(context),
    );
    if (!context.mounted) return;
  }
  await vm.start.execute();
  if (!context.mounted) return;
  if (vm.start.result case Ok(:final value)) {
    // The click of the lamp: Reading opens with the user's Window coming on.
    unawaited(HapticFeedback.lightImpact());
    await context.push('/reading/$value');
  }
}

/// Why the app wants to post a notification, before the system asks.
class _NotificationExplainer extends StatelessWidget {
  const _NotificationExplainer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: Palette.panel,
      icon: const Icon(Icons.lock_clock_outlined, color: Palette.lamp),
      title: Text(l10n.notificationAskTitle),
      content: Text(l10n.notificationAskBody),
      actions: [
        TextButton(
          key: const Key('notificationNotNow'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.notificationAskNotNow),
        ),
        FilledButton(
          key: const Key('notificationAllow'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.notificationAskAllow),
        ),
      ],
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.road, required this.evenings});

  final Road road;
  final int? evenings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final work = road.work;
    final next = nextCheckpoint(context, road);
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
            // The title opens the Book page: the Road and the Notes so far.
            InkWell(
              onTap: () => context.push('/book/${work.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(work.title, style: text.titleLarge),
                  if (work.author.isNotEmpty)
                    Text(work.author, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RoadView(road: road),
            const SizedBox(height: 12),
            Text(
              positionOf(l10n, Localizations.localeOf(context), road),
              style: text.bodyMedium,
            ),
            Text(amountLeft(context, road), style: text.bodySmall),
            if (evenings case final n?)
              Text(l10n.eveningsLeft(n), style: text.bodySmall),
            if (next != null) Text(next, style: text.bodySmall),
            // On the row "Change book" already takes, so Start stays put.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (context.read<AppWatch>().available) _WhereIsIt(work: work),
                TextButton(
                  onPressed: () => context.go('/books'),
                  child: Text(l10n.changeBook),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Paper or this phone, asked before Start so the Work app is set before
/// an Urge could need it. It's the Work's Work app, kept as the Reading card
/// keeps it, and still changeable there.
class _WhereIsIt extends StatelessWidget {
  const _WhereIsIt({required this.work});

  final Work work;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsViewModel>();
    final app = settings.workApps[work.id];
    return Semantics(
      container: true,
      label: l10n.workAppPick,
      // Side by side always; a long app name shortens instead.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChoiceChip(
            label: Text(l10n.whereIsElsewhere(work.kind.name)),
            selected: app == null,
            onSelected: (_) => settings.setWorkApp(work.id, null),
          ),
          const SizedBox(width: 8),
          // Tapped again, it asks again: that's how the app is changed.
          Flexible(
            child: ChoiceChip(
              label: Text(
                app?.label ?? l10n.whereIsPhone,
                overflow: TextOverflow.ellipsis,
              ),
              selected: app != null,
              onSelected: (_) => pickWorkApp(context, work.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// One cell per night this week: lit where there was a Session, dark
/// otherwise, and tonight outlined until it's lit. A missed night looks just
/// like one still to come; nothing here ever "breaks".
class _ReadingWeekStrip extends StatelessWidget {
  const _ReadingWeekStrip({required this.week});

  final ReadingWeek week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final letters = MaterialLocalizations.of(context).narrowWeekdays;
    final count = l10n.readingWeekCount(week.count);
    final mute = text.bodySmall?.copyWith(color: Palette.mute);
    return Semantics(
      container: true,
      label: '${l10n.readingWeekTitle}. $count',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.readingWeekTitle, style: mute),
              Text(count, style: text.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, night) in week.nights.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _NightCell(
                        key: ValueKey(night),
                        lit: week.isLit(night),
                        tonight: night == week.tonight,
                      ),
                      const SizedBox(height: 4),
                      // narrowWeekdays starts on Sunday, which is weekday 7.
                      Text(letters[night.weekday % 7], style: mute),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NightCell extends StatelessWidget {
  const _NightCell({required this.lit, required this.tonight, super.key});

  final bool lit;
  final bool tonight;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    decoration: BoxDecoration(
      color: lit ? Palette.lamp : (tonight ? null : Palette.unlit),
      border: Border.all(
        color: lit ? Palette.lamp : (tonight ? Palette.me : Palette.line),
        width: tonight && !lit ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
