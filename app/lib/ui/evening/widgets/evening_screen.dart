import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/voice_text.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/evening/view_models/evening_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// End of the evening: which page, one sentence, and lights out.
class EveningScreen extends StatelessWidget {
  const EveningScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => EveningViewModel(c.read<SessionRepository>(), sessionId),
    child: const _Evening(),
  );
}

class _Evening extends StatefulWidget {
  const _Evening();

  @override
  State<_Evening> createState() => _EveningState();
}

class _EveningState extends State<_Evening> {
  final _page = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(EveningViewModel vm) async {
    final timed = vm.record!.road.work.kind.unit == WorkUnit.second;
    await vm.save.execute((
      page: timed ? parseClock(_page.text) : parseNumber(_page.text),
      note: _note.text,
    ));
    if (!mounted || !vm.save.completed) return;
    // Entering the last page is the Finish: the Building grows a floor.
    context.go(
      vm.finished ? '/building/finish/${vm.record!.road.work.id}' : '/tonight',
    );
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

    return Scaffold(
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
                      SizedBox(
                        width: unit == WorkUnit.second ? 168 : 120,
                        child: TextField(
                          key: const Key('page'),
                          controller: _page,
                          keyboardType: unit == WorkUnit.second
                              ? TextInputType.datetime
                              : TextInputType.number,
                          // A timestamp reads like a clock, which never
                          // mirrors.
                          textDirection: unit == WorkUnit.second
                              ? TextDirection.ltr
                              : null,
                          style: text.headlineSmall,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            errorText: pageProblem,
                            errorMaxLines: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(switch (unit) {
                            WorkUnit.page => l10n.ofStartedAt(total, from),
                            WorkUnit.episode => l10n.ofStartedAtEpisode(
                              total,
                              from,
                            ),
                            WorkUnit.second => l10n.ofStartedAtTime(
                              totalText,
                              fromText,
                            ),
                          }, style: text.bodySmall),
                        ),
                      ),
                    ],
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
