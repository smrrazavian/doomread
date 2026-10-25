import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/building/view_models/building_view_model.dart';
import 'package:doomread/ui/building/widgets/building_view.dart';
import 'package:doomread/ui/building/widgets/longest_stretch_trend.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/settings_button.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/share/widgets/glow_up_poster.dart';
import 'package:doomread/ui/share/widgets/month_poster.dart';
import 'package:doomread/ui/share/widgets/share_preview_screen.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The user's own tower: one floor per Finish, the newest on top.
class BuildingScreen extends StatelessWidget {
  const BuildingScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => BuildingViewModel(c.read<SessionRepository>()),
    child: const _Building(),
  );
}

class _Building extends StatelessWidget {
  const _Building();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<BuildingViewModel>();
    final floors = vm.floors;
    final sharing = canShare(context);
    // Until the Calendar has it, the month of windows is shared from here.
    final month = vm.month(solarHijri: calendarOf(context).solarHijri);
    VoidCallback? shareGlowUp(
      List<StretchRise> rises, {
      required bool watched,
    }) => sharing
        ? () => openSharePreview(
            context,
            GlowUpPoster(rises: rises, watched: watched),
          )
        : null;
    return Scaffold(
      appBar: AppBar(actions: const [SettingsButton()]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
          children: [
            Text(l10n.buildingTitle, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(
              l10n.buildingSub,
              style: text.bodyMedium?.copyWith(color: Palette.mute),
            ),
            const SizedBox(height: 24),
            // Reading and watching each have their own Longest stretch; the
            // labels only appear once there's watching to tell apart.
            if (vm.watchingRises.isNotEmpty) ...[
              Text(l10n.trendReading, style: text.titleSmall),
              const SizedBox(height: 8),
            ],
            LongestStretchTrend(
              rises: vm.rises,
              onShare: shareGlowUp(vm.rises, watched: false),
            ),
            if (vm.watchingRises.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(l10n.trendWatching, style: text.titleSmall),
              const SizedBox(height: 8),
              LongestStretchTrend(
                rises: vm.watchingRises,
                onShare: shareGlowUp(vm.watchingRises, watched: true),
              ),
            ],
            if (sharing && month.count > 0)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () =>
                      openSharePreview(context, MonthPoster(month: month)),
                  icon: const Icon(Icons.calendar_view_month_outlined),
                  label: Text(l10n.cardMonthAction),
                ),
              ),
            const SizedBox(height: 24),
            BuildingView(floors: floors.length, highlighted: 0),
            const SizedBox(height: 16),
            if (floors.isEmpty && vm.loaded)
              Text(l10n.buildingEmpty, style: text.bodyMedium),
            for (final (i, finish) in floors.indexed)
              _FloorRow(finish: finish, newest: i == 0),
          ],
        ),
      ),
    );
  }
}

/// One finished Work in the list under the tower.
class _FloorRow extends StatelessWidget {
  const _FloorRow({required this.finish, required this.newest});

  final Finish finish;
  final bool newest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: newest ? const Key('newestFloor') : null,
      onTap: () => context.push('/book/${finish.work.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Palette.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(
                color: newest ? Palette.me : Palette.tickPassed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finish.work.title,
                    style: text.titleMedium?.copyWith(
                      fontFamily: bookFamily(context),
                      color: newest ? Palette.me : Palette.paper,
                    ),
                  ),
                  Text(
                    floorDetails(context, finish),
                    style: text.bodySmall?.copyWith(color: Palette.mute),
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
