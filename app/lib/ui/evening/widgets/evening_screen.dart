import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/one_session.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/evening/view_models/evening_view_model.dart';
import 'package:doomread/ui/evening/widgets/rolling_field.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/ui/share/widgets/receipt_poster.dart';
import 'package:doomread/ui/share/widgets/share_preview_screen.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
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
    // Its own messenger, so the Stop's Resume goes when this screen does.
    child: ScaffoldMessenger(
      child: _Evening(
        finishing: GoRouterState.of(context).uri.queryParameters
            .containsKey(_finishing),
        reopen: GoRouterState.of(context).uri.queryParameters
            .containsKey(_reopen),
      ),
    ),
  );
}

/// Where End of the evening is for [sessionId]. When [finishing], the user
/// said "I finished it!" already, so the page starts at the Work's end and
/// what's left is the Note; saving is then the Finish. With [reopen], the
/// user just tapped Stop, so it's offered back, in case that was a mistake.
String eveningPath(
  String sessionId, {
  bool finishing = false,
  bool reopen = false,
}) {
  final flags = [if (finishing) _finishing, if (reopen) _reopen];
  return '/evening/$sessionId${flags.isEmpty ? '' : '?${flags.join('&')}'}';
}

const _finishing = 'finishing';
const _reopen = 'reopen';

class _Evening extends StatefulWidget {
  const _Evening({required this.finishing, required this.reopen});

  final bool finishing;
  final bool reopen;

  @override
  State<_Evening> createState() => _EveningState();
}

/// How long the light takes to go off, and how dark it gets.
const _lightsOutTime = Duration(milliseconds: 450);
const _lightsOutDarkness = 0.85;

class _EveningState extends State<_Evening>
    with SingleTickerProviderStateMixin {
  // Made on the first build with the journal loaded, prefilled then.
  TextEditingController? _page;
  final _note = TextEditingController();

  // The page's last step on the steppers, for the field to roll over.
  Roll? _roll;

  // Lights out, before leaving for Tonight.
  late final _dim = AnimationController(vsync: this, duration: _lightsOutTime);

  @override
  void initState() {
    super.initState();
    if (widget.reopen) {
      // "Stopped by mistake?": Resume takes the Stop back, and goes back
      // to the Session.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final vm = context.read<EveningViewModel>();
        offerReopen(context, vm.id, () async {
          await vm.reopen();
          if (mounted) context.pushReplacement('/reading/${vm.id}');
        });
      });
    }
  }

  @override
  void dispose() {
    _page?.dispose();
    _note.dispose();
    _dim.dispose();
    super.dispose();
  }

  int? _typed(Work work) => work.kind.unit == WorkUnit.second
      ? parseClock(_page!.text)
      : parseNumber(_page!.text);

  /// Saves [page], or what the user typed. With [share], tonight's receipt
  /// opens to share once it's saved, and the evening goes on after it.
  Future<void> _save(
    EveningViewModel vm, {
    int? page,
    bool share = false,
  }) async {
    await vm.save.execute((
      page: page ?? _typed(vm.record!.road.work),
      note: _note.text,
    ));
    if (!mounted || !vm.save.completed) return;
    if (share) {
      final saved = await vm.saved();
      if (!mounted) return;
      if (saved case (final record, final session)) {
        await openSharePreview(
          context,
          ReceiptPoster(
            work: record.road.work,
            session: session,
            pages: record.pages,
            signOff: receiptSignOff(
              session,
              context.read<SettingsViewModel>().tone,
              Localizations.localeOf(context).languageCode,
            ),
          ),
        );
        if (!mounted) return;
      }
    }
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
    setState(() => _roll = Roll(from: from, to: to, up: by > 0));
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
    final from = record.startPage;
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

    final sharing = canShare(context);
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
                        child: RollingField(
                          roll: _roll,
                          style: text.bodyLarge!.merge(text.headlineSmall),
                          builder: (context, {required hidden}) => TextField(
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
                            style: hidden
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
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: vm.save.running ? null : () => _save(vm),
                      child: Text(l10n.saveAndLightsOut),
                    ),
                  ),
                  // Quiet and opt-in: saving never shares by itself.
                  if (sharing) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      key: const Key('shareTonight'),
                      tooltip: l10n.cardShareTonight,
                      onPressed: vm.save.running
                          ? null
                          : () => _save(vm, share: true),
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ],
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
                  alpha:
                      _lightsOutDarkness * Curves.easeIn.transform(_dim.value),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
