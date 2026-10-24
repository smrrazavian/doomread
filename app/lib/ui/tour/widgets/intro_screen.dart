import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/books/view_models/work_form_view_model.dart';
import 'package:doomread/ui/core/empty_scenes.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/ui/tone/widgets/tone_screen.dart';
import 'package:doomread/ui/tour/view_models/tour_view_model.dart';
import 'package:doomread/ui/tour/widgets/intro_scenes.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The first run: three cards that tell the movie-night story and pick the
/// Tone, then "What are you trying to finish?", whose Start is the first
/// Session. With [replay], from Settings, only the cards, then back.
class IntroScreen extends StatelessWidget {
  const IntroScreen({this.replay = false, super.key});

  final bool replay;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => WorkFormViewModel(c.read<WorkRepository>()),
    child: _Intro(replay: replay),
  );
}

class _Intro extends StatefulWidget {
  const _Intro({required this.replay});

  final bool replay;

  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> {
  static const _cards = 3;
  var _step = 0;

  final _title = TextEditingController();
  final _length = TextEditingController();
  WorkKind _kind = WorkKind.paperBook;

  @override
  void dispose() {
    _title.dispose();
    _length.dispose();
    super.dispose();
  }

  /// Out of the intro: back where the replay came from, or to Tonight.
  void _leave() {
    if (widget.replay) {
      context.pop();
    } else {
      context.go('/tonight');
    }
  }

  Future<void> _skip() async {
    if (widget.replay) {
      _leave();
      return;
    }
    await context.read<TourViewModel>().skipIntro();
    if (mounted) _leave();
  }

  /// "Later" on the Work step: the intro is done, without a Work yet.
  Future<void> _later() async {
    await context.read<TourViewModel>().finishIntro();
    if (mounted) _leave();
  }

  void _next() {
    if (_step == _cards - 1 && widget.replay) return _leave();
    setState(() => _step++);
  }

  Future<void> _start() async {
    final vm = context.read<WorkFormViewModel>();
    final tour = context.read<TourViewModel>();
    final timed = _kind.unit == WorkUnit.second;
    await vm.save.execute(
      WorkDraft(
        title: _title.text,
        author: '',
        totalPages: (timed ? parseClock : parseNumber)(_length.text) ?? 0,
        checkpoints: const [],
        kind: _kind,
      ),
    );
    if (vm.save.result is! Ok) return;
    await tour.finishIntro(startNow: true);
    if (mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final calm = MediaQuery.disableAnimationsOf(context);
    final working = _step == _cards;
    final Widget card = switch (_step) {
      0 => _Card(
        scene: MovieNightPainter.new,
        heading: l10n.tourStoryTitle,
        body: l10n.tourStoryBody,
        top: const _LanguageSwitch(),
      ),
      1 => _Card(
        scene: CompanyPainter.new,
        // Its Windows come on one after another: a little slower.
        duration: const Duration(milliseconds: 2400),
        heading: l10n.tourCompanyTitle,
        body: l10n.tourCompanyBody,
      ),
      2 => const _ToneCard(),
      _ => _WorkStep(
        title: _title,
        length: _length,
        kind: _kind,
        onKind: (k) => setState(() => _kind = k),
        onDone: _start,
      ),
    };
    final next = switch (_step) {
      0 => l10n.tourStoryNext,
      1 => l10n.tourCompanyNext,
      2 => l10n.tourToneNext,
      _ => l10n.startWork(_kind.name),
    };
    final saving = context.watch<WorkFormViewModel>().save.running;
    return PopScope(
      // System back walks back through the cards.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Progress(step: _step, of: _cards),
                    const Spacer(),
                    TextButton(
                      key: const Key('introSkip'),
                      onPressed: working ? _later : _skip,
                      child: Text(working ? l10n.tourLater : l10n.tourSkip),
                    ),
                  ],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: calm
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(key: ValueKey(_step), child: card),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('introNext'),
                  onPressed: saving ? null : (working ? _start : _next),
                  child: Text(next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How far through the cards: three little windows, lit up to this one.
class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.of});

  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        for (var i = 0; i < of; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              width: 10,
              height: 13,
              decoration: BoxDecoration(
                color: i <= step ? Palette.lamp : Palette.unlit,
                border: Border.all(
                  color: i <= step ? Palette.lamp : Palette.line,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    ),
  );
}

/// One story card: its painted scene, a heading and a line or two.
class _Card extends StatelessWidget {
  const _Card({
    required this.scene,
    required this.heading,
    required this.body,
    this.duration = const Duration(milliseconds: 1600),
    this.top,
  });

  final ScenePainter Function(Animation<double> light, {required bool rtl})
  scene;
  final Duration duration;
  final String heading;
  final String body;

  /// Above the scene, on the first card: the language switch.
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top case final top?) ...[const SizedBox(height: 8), top],
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PaintedScene(scene, maxWidth: 360, duration: duration),
          ),
        ),
        const SizedBox(height: 32),
        Text(heading, style: text.headlineSmall),
        const SizedBox(height: 12),
        Text(body, style: text.bodyMedium),
      ],
    );
  }
}

/// English or Persian, each named in itself, on the first card. It flips
/// the whole intro at once and is saved as Settings saves it.
class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  static const _languages = {'en': 'English', 'fa': 'فارسی'};

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final current = Localizations.localeOf(context).languageCode;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        container: true,
        label: AppLocalizations.of(context).language,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Palette.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final MapEntry(:key, :value) in _languages.entries)
                  _LanguageOption(
                    key: Key('language_$key'),
                    label: value,
                    selected: key == current,
                    onTap: () => settings.setLocale(Locale(key)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.labelLarge!;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Palette.indicator : null,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            // Each name in its own face, whatever the app is in now.
            style: text.copyWith(
              fontFamily: label == 'English'
                  ? 'BricolageGrotesque'
                  : 'VazirmatnUI',
              color: selected ? Palette.paper : Palette.mute,
            ),
          ),
        ),
      ),
    );
  }
}

/// The third card: the same moment in each Tone, as speech bubbles, and a
/// tap picks one.
class _ToneCard extends StatelessWidget {
  const _ToneCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final settings = context.watch<SettingsViewModel>();
    return ListView(
      padding: const EdgeInsets.only(top: 24),
      children: [
        Text(l10n.tourToneTitle, style: text.headlineSmall),
        const SizedBox(height: 12),
        Text(l10n.tourToneBody, style: text.bodyMedium),
        const SizedBox(height: 24),
        for (final t in Tone.values) ...[
          _Bubble(
            tone: t,
            selected: settings.tone == t,
            onTap: () => settings.setTone(t),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.tourToneLater,
          style: text.bodySmall?.copyWith(color: Palette.mute),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final Tone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    // Speech bubbles with the tail at the start, like a message coming in.
    const shape = BorderRadiusDirectional.only(
      topStart: Radius.circular(18),
      topEnd: Radius.circular(18),
      bottomEnd: Radius.circular(18),
      bottomStart: Radius.circular(4),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: Key('tone_${tone.name}'),
        onTap: onTap,
        borderRadius: shape.resolve(Directionality.of(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: selected ? Palette.raise : Palette.panel,
                border: Border.all(
                  color: selected ? Palette.lamp : Palette.line,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: shape,
              ),
              child: Text(toneSample(context, tone), style: text.bodyMedium),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Row(
                children: [
                  if (selected) ...[
                    const Icon(Icons.check, size: 16, color: Palette.lamp),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    toneName(l10n, tone),
                    style: text.labelLarge?.copyWith(
                      color: selected ? Palette.lamp : Palette.mute,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "What are you trying to finish?": the kind, the title and the length.
/// Checkpoints can wait for the Work's own page.
class _WorkStep extends StatelessWidget {
  const _WorkStep({
    required this.title,
    required this.length,
    required this.kind,
    required this.onKind,
    required this.onDone,
  });

  final TextEditingController title;
  final TextEditingController length;
  final WorkKind kind;
  final ValueChanged<WorkKind> onKind;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<WorkFormViewModel>();
    final timed = kind.unit == WorkUnit.second;
    String? problem(WorkProblem p, String message) =>
        vm.problems.contains(p) ? message : null;
    return ListView(
      padding: const EdgeInsets.only(top: 24),
      children: [
        Text(l10n.tourWorkTitle, style: text.headlineSmall),
        const SizedBox(height: 12),
        Text(l10n.tourWorkBody, style: text.bodyMedium),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in WorkKind.values)
              ChoiceChip(
                key: Key(k.name),
                avatar: Icon(kindIcon(k)),
                label: Text(kindName(l10n, k)),
                showCheckmark: false,
                selected: k == kind,
                onSelected: (_) => onKind(k),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('title'),
          controller: title,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.fieldTitle,
            errorText: problem(WorkProblem.noTitle, l10n.problemNoTitle),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('pages'),
          controller: length,
          keyboardType: timed ? TextInputType.datetime : TextInputType.number,
          textDirection: timed ? TextDirection.ltr : null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onDone(),
          decoration: InputDecoration(
            labelText: switch (kind.unit) {
              WorkUnit.page => l10n.fieldPages,
              WorkUnit.episode => l10n.fieldEpisodes,
              WorkUnit.second => l10n.fieldDuration,
            },
            hintText: timed ? l10n.fieldDurationHint : null,
            errorText: problem(WorkProblem.noPages, switch (kind.unit) {
              WorkUnit.page => l10n.problemNoPages,
              WorkUnit.episode => l10n.problemNoEpisodes,
              WorkUnit.second => l10n.problemNoDuration,
            }),
          ),
        ),
      ],
    );
  }
}
