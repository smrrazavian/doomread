import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/building/view_models/building_view_model.dart';
import 'package:doomread/ui/building/widgets/building_view.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/share/widgets/share_preview_screen.dart';
import 'package:doomread/ui/share/widgets/yalda_poster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The last page: a new floor lights up on the Building, with what it took.
class FinishScreen extends StatelessWidget {
  const FinishScreen({required this.workId, super.key});

  final String workId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => BuildingViewModel(c.read<SessionRepository>()),
    child: _Finish(workId),
  );
}

class _Finish extends StatelessWidget {
  const _Finish(this.workId);

  final String workId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final vm = context.watch<BuildingViewModel>();
    final floors = vm.floors;
    final yalda = vm.yalda;
    final floor = floors.indexWhere((f) => f.work.id == workId);
    if (floor < 0) return const Scaffold();
    final finish = floors[floor];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The top of the tower only: the new floor is the moment.
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _Thud(
                child: BuildingView(
                  floors: floors.length,
                  highlighted: floor,
                  lightUp: true,
                  maxFloors: 3,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
                children: [
                  Text(
                    l10n.finishedTitle(finish.work.title),
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(finishedSub(context, finish), style: text.bodyMedium),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _Tally(
                        number: l10n.minutesShort(
                          finish.longestStretch.inMinutes,
                        ),
                        label: l10n.longestStretchLabel,
                      ),
                      const SizedBox(width: 32),
                      _Tally(
                        number: formatNumber(finish.notes, locale),
                        label: l10n.notesWritten(finish.notes),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () => context.go('/building'),
                    child: Text(l10n.seeYourBuilding),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/book/$workId'),
                    child: Text(l10n.readTheStory),
                  ),
                  if (canShare(context)) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => openFinishPreview(
                        context,
                        finish: finish,
                        floors: floors.length,
                        floor: floor,
                      ),
                      child: Text(l10n.shareAction),
                    ),
                  ],
                  // Finished on Shab-e Yalda: its poster too.
                  if (yalda != null && canShareYalda(context, yalda)) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => showYaldaPoster(context, yalda),
                      child: Text(l10n.yaldaShare),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A firm haptic, once, as the new floor starts to light.
class _Thud extends StatefulWidget {
  const _Thud({required this.child});

  final Widget child;

  @override
  State<_Thud> createState() => _ThudState();
}

class _ThudState extends State<_Thud> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(HapticFeedback.heavyImpact()),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Tally extends StatelessWidget {
  const _Tally({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: text.headlineSmall?.copyWith(fontSize: 24)),
        Text(label, style: text.bodySmall?.copyWith(color: Palette.mute)),
      ],
    );
  }
}
