import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/planned_break/break_text.dart';
import 'package:doomread/ui/planned_break/view_models/planned_break_view_model.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// The "not yet" screen over a Watched app: the House, how far the next
/// Planned break is, a big way back and a full-size way on. Like after a
/// Slip, it says "not yet", never "don't".
class UrgeView extends StatelessWidget {
  const UrgeView({
    required this.record,
    required this.house,
    required this.app,
    required this.onBack,
    required this.onOpen,
    super.key,
  });

  final SessionRecord record;
  final List<HouseWindow> house;

  /// The app's name, or null when it isn't known.
  final String? app;
  final VoidCallback onBack;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final work = record.road.work;
    // Letting it pass is a small win: a light tap to say so.
    void back() {
      unawaited(HapticFeedback.lightImpact());
      onBack();
    }

    // System back is "Back to the book" too.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: _Moment(
        house: house,
        kind: work.kind,
        title: say(context, Moment.urge, {'app': ?app}),
        body: [
          ChangeNotifierProvider(
            create: (c) =>
                PlannedBreakViewModel(c.read<SessionRepository>(), record.id),
            child: const _BreakDistance(),
          ),
          l10n.urgeBody,
        ],
        go: work.kind.unit == WorkUnit.page
            ? l10n.backToBook
            : l10n.backToWork(work.kind.name),
        onGo: back,
        quiet: app == null ? l10n.openItAnyway : l10n.openAnyway(app!),
        onQuiet: onOpen,
      ),
    );
  }
}

/// After a Slip, when the user comes back: kind in every Tone, never a roast.
class AfterSlipView extends StatelessWidget {
  const AfterSlipView({
    required this.session,
    required this.house,
    required this.onBackIn,
    required this.onDone,
    super.key,
  });

  final Session session;
  final List<HouseWindow> house;
  final VoidCallback onBackIn;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = session.stretches.lastOrNull?.length ?? Duration.zero;
    return _Moment(
      house: house,
      title: say(context, Moment.afterSlip),
      body: [l10n.slipBody(last.inMinutes)],
      go: l10n.backIn,
      onGo: onBackIn,
      quiet: l10n.doneForTonight,
      onQuiet: onDone,
    );
  }
}

/// How far the next Planned break is, or nothing when the Finish comes
/// first.
class _BreakDistance extends StatelessWidget {
  const _BreakDistance();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlannedBreakViewModel>();
    final record = vm.record;
    final offer = vm.offer;
    if (record == null || offer == null) return const SizedBox.shrink();
    return Text(
      breakLine(
        AppLocalizations.of(context),
        Localizations.localeOf(context),
        record.road.work,
        offer.checkpoint,
        minutesUp(vm.toGo),
      ),
    );
  }
}

/// The House on top, a heading and a few lines, then a big button and a
/// full-size quiet one, as in the mockups.
class _Moment extends StatelessWidget {
  const _Moment({
    required this.house,
    required this.title,
    required this.body,
    required this.go,
    required this.onGo,
    required this.quiet,
    required this.onQuiet,
    this.kind,
  });

  final List<HouseWindow> house;
  final WorkKind? kind;
  final String title;

  /// Lines of text, or widgets.
  final List<Object> body;
  final String go;
  final VoidCallback onGo;
  final String quiet;
  final VoidCallback onQuiet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final soft = text.bodyMedium!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: HouseView(windows: house, kind: kind),
                ),
              ),
              const SizedBox(height: 32),
              Text(title, style: text.headlineSmall),
              const SizedBox(height: 8),
              for (final b in body)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: DefaultTextStyle(
                    style: soft,
                    child: b is Widget ? b : Text(b as String),
                  ),
                ),
              const SizedBox(height: 48),
              FilledButton(onPressed: onGo, child: Text(go)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onQuiet, child: Text(quiet)),
            ],
          ),
        ),
      ),
    );
  }
}
