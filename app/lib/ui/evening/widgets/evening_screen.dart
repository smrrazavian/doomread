import 'dart:math' as math;

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/evening/view_models/evening_view_model.dart';
import 'package:doomread/ui/evening/widgets/odometer.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// End of the evening: which page, one sentence, and lights out. The page
/// rolls like an odometer on the steppers, and saving dims the screen
/// before Tonight, as a lamp turned off would.
class EveningScreen extends StatelessWidget {
  const EveningScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => EveningViewModel(c.read<SessionRepository>(), sessionId),
    child: _Evening(
      finishing: GoRouterState.of(context).uri.queryParameters
          .containsKey(_finishing),
    ),
  );
}

/// Where End of the evening is for [sessionId]. When [finishing], the user
/// said "I finished it!" already, so the page starts at the Work's end and
/// what's left is the Note; saving is then the Finish.
String eveningPath(String sessionId, {bool finishing = false}) =>
    '/evening/$sessionId${finishing ? '?$_finishing' : ''}';

const _finishing = 'finishing';

class _Evening extends StatefulWidget {
  const _Evening({required this.finishing});

  final bool finishing;

  @override
  State<_Evening> createState() => _EveningState();
}

class _EveningState extends State<_Evening> with TickerProviderStateMixin {
  // Made on the first build with the journal loaded, prefilled then.
  TextEditingController? _page;
  final _note = TextEditingController();

  // The page rolling from one number to the next, and which way.
  late final _roll = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  ({String from, String to, bool up}) _rolled = (from: '', to: '', up: true);
  // Where the field's text sits, so the roll lands exactly on it.
  final GlobalKey _field = GlobalKey();
  Rect? _textAt;

  // Lights out, before leaving for Tonight.
  late final _dim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    // The field shows its own text again once the roll is over.
    _roll.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() {});
    });
  }

  @override
  void dispose() {
    _page?.dispose();
    _note.dispose();
    _roll.dispose();
    _dim.dispose();
    super.dispose();
  }

  int? _typed(Work work) => work.kind.unit == WorkUnit.second
      ? parseClock(_page!.text)
      : parseNumber(_page!.text);

  /// Saves [page], or what the user typed.
  Future<void> _save(EveningViewModel vm, {int? page}) async {
    await vm.save.execute((
      page: page ?? _typed(vm.record!.road.work),
      note: _note.text,
    ));
    if (!mounted || !vm.save.completed) return;
    // The Finish has its own moment; otherwise the light goes off first.
    if (!vm.finished && !MediaQuery.disableAnimationsOf(context)) {
      await _dim.forward();
      if (!mounted) return;
    }
    // Entering the last page is the Finish: the Building grows a floor.
    context.go(
      vm.finished ? '/building/finish/${vm.record!.road.work.id}' : '/tonight',
    );
  }

  void _step(EveningViewModel vm, int by) {
    final work = vm.record!.road.work;
    final from = _page!.text;
    final to = formatAmount(context, work, vm.step(_typed(work), by));
    _page!.text = to;
    if (from == to || MediaQuery.disableAnimationsOf(context)) return;
    final box = _field.currentContext?.findRenderObject() as RenderBox?;
    final text = box == null ? null : _editable(box);
    if (box == null || text == null) return;
    // Centred text keeps its middle whatever the number, so the roll is
    // centred on the old one's: the field keeps room for the caret on one
    // side, off the box's own middle.
    final at = text.localToGlobal(Offset.zero, ancestor: box) & text.size;
    final glyphs = text
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: from.length),
        )
        .map((b) => b.toRect())
        .fold<Rect?>(null, (all, r) => all?.expandToInclude(r) ?? r);
    final middle = glyphs == null ? at.center.dx : at.left + glyphs.center.dx;
    final half = math.min(middle - at.left, at.right - middle);
    setState(() {
      _textAt = Rect.fromLTRB(middle - half, at.top, middle + half, at.bottom);
      _rolled = (from: from, to: to, up: by > 0);
    });
    _roll.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<EveningViewModel>();
    final record = vm.record;
    if (record == null) return const Scaffold();
    final work = record.road.work;
    final unit = work.kind.unit;
    final from = record.road.position;
    final total = work.totalPages;
    final (fromText, totalText) = (
      formatAmount(context, work, from),
      formatAmount(context, work, total),
    );
    final page = _page ??= TextEditingController(
      text: formatAmount(
        context,
        work,
        widget.finishing ? total : vm.suggested,
      ),
    );
    final String? pageProblem;
    if (vm.problems.contains(SessionEndProblem.noPage)) {
      pageProblem = switch (unit) {
        WorkUnit.page => l10n.problemNoPage,
        WorkUnit.episode => l10n.problemNoEpisode,
        WorkUnit.second => l10n.problemNoTime,
      };
    } else if (vm.problems.contains(SessionEndProblem.pageOutOfRange)) {
      pageProblem = switch (unit) {
        WorkUnit.page => l10n.problemPageOutOfRange(from, total),
        WorkUnit.episode => l10n.problemEpisodeOutOfRange(from, total),
        WorkUnit.second => l10n.problemTimeOutOfRange(fromText, totalText),
      };
    } else {
      pageProblem = null;
    }

    final screen = Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
                children: [
                  if (vm.newBest) ...[
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _NewBest(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    (work.kind.watched
                        ? l10n.inOneGoTonightWatched
                        : l10n.inOneGoTonight)(vm.longestTonight.inMinutes),
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(say(context, Moment.evening), style: text.bodyMedium),
                  const SizedBox(height: 32),
                  Text(switch (unit) {
                    WorkUnit.page => l10n.whichPage,
                    WorkUnit.episode => l10n.whichEpisode,
                    WorkUnit.second => l10n.whereStopped,
                  }, style: text.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level with the field, which grows downwards with a
                      // problem under it.
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: IconButton.filledTonal(
                          key: const Key('pageDown'),
                          onPressed: () => _step(vm, -1),
                          icon: const Icon(Icons.remove),
                          iconSize: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: unit == WorkUnit.second ? 152 : 104,
                        child: _rolling(
                          context,
                          TextField(
                            key: const Key('page'),
                            controller: page,
                            textAlign: TextAlign.center,
                            keyboardType: unit == WorkUnit.second
                                ? TextInputType.datetime
                                : TextInputType.number,
                            // A timestamp reads like a clock, which never
                            // mirrors.
                            textDirection: unit == WorkUnit.second
                                ? TextDirection.ltr
                                : null,
                            style: _roll.isAnimating
                                ? text.headlineSmall!.copyWith(
                                    color: Colors.transparent,
                                  )
                                : text.headlineSmall,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              errorText: pageProblem,
                              errorMaxLines: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: IconButton.filledTonal(
                          key: const Key('pageUp'),
                          onPressed: () => _step(vm, 1),
                          icon: const Icon(Icons.add),
                          iconSize: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.eveningOfTotal(totalText), style: text.bodyMedium),
                  const SizedBox(height: 4),
                  Text(switch (unit) {
                    WorkUnit.page => l10n.eveningStartedAtPage(from),
                    WorkUnit.episode => l10n.eveningStartedAtEpisode(from),
                    WorkUnit.second => l10n.eveningStartedAtTime(fromText),
                  }, style: text.bodySmall),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: vm.save.running
                          ? null
                          : () => _save(vm, page: total),
                      child: Text(l10n.eveningFinished),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.whatHappened, style: text.bodyMedium),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('note'),
                    controller: _note,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontFamily: bookFamily(context)),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
              child: FilledButton(
                onPressed: vm.save.running ? null : () => _save(vm),
                child: Text(l10n.saveAndLightsOut),
              ),
            ),
          ],
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _dim,
      child: screen,
      // Always a Stack, so the screen under it keeps its state (the Note's
      // focus, the scroll) as the light goes off.
      builder: (context, screen) => Stack(
        children: [
          screen!,
          if (!_dim.isDismissed)
            Positioned.fill(
              key: const Key('lightsOut'),
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.85 * Curves.easeIn.transform(_dim.value),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The page field, with the number rolling over it while it changes.
  Widget _rolling(BuildContext context, Widget field) => AnimatedBuilder(
    animation: _roll,
    child: field,
    builder: (context, field) => Stack(
      key: _field,
      children: [
        field!,
        if (_roll.isAnimating && _textAt != null)
          Positioned.fromRect(
            rect: _textAt!,
            child: IgnorePointer(
              child: Odometer(
                from: _rolled.from,
                to: _rolled.to,
                up: _rolled.up,
                t: Curves.easeOutCubic.transform(_roll.value),
                style: Theme.of(context).textTheme.bodyLarge!
                    .merge(Theme.of(context).textTheme.headlineSmall),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The field's text, found in its render tree.
RenderEditable? _editable(RenderObject o) {
  if (o is RenderEditable) return o;
  RenderEditable? found;
  o.visitChildren((c) => found ??= _editable(c));
  return found;
}

/// The "new best stretch" moment.
class _NewBest extends StatelessWidget {
  const _NewBest();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Palette.lamp),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        AppLocalizations.of(context).newBestStretch,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Palette.lamp),
      ),
    ),
  );
}
