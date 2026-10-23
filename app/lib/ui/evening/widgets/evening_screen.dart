import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
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
    await vm.save.execute((page: parseNumber(_page.text), note: _note.text));
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
    final from = record.road.position;
    final total = record.road.work.totalPages;
    final String? pageProblem;
    if (vm.problems.contains(SessionEndProblem.noPage)) {
      pageProblem = l10n.problemNoPage;
    } else if (vm.problems.contains(SessionEndProblem.pageOutOfRange)) {
      pageProblem = l10n.problemPageOutOfRange(from, total);
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
                    l10n.inOneGoTonight(vm.longestTonight.inMinutes),
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  Text(l10n.whichPage, style: text.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          key: const Key('page'),
                          controller: _page,
                          keyboardType: TextInputType.number,
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
                          child: Text(
                            l10n.ofStartedAt(total, from),
                            style: text.bodySmall,
                          ),
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
