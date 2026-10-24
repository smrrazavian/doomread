import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// The month as a building at night: one Window per night, a floor per
/// week, brighter for a longer night of reading. A night without a Session
/// stays dark, and nights still to come are just wall-coloured glass.
///
/// Persian gets the Solar Hijri month, Saturday at the start (the right),
/// and Persian digits. How bright a night is depends only on the user's own
/// brightest night this month.
class MonthPoster extends StatelessWidget {
  const MonthPoster({required this.month, required this.firstDay, super.key});

  final ReadingMonth month;

  /// The weekday the week starts on, see [firstDayOfWeek].
  final int firstDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fa = isPersian(context);
    final type = PosterType(fa: fa);
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;
    final lead = month.leadingDays(firstDay);
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      ...month.nights,
    ];
    final weeks = (cells.length / 7).ceil();
    final heading = type.title.copyWith(fontSize: fa ? 27 : 29);

    return PosterCanvas(
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: PosterSky(stars: 34, starDepth: 0.2)),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 26, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wordmark(l10n.appTitle, type.mark),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.cardMonthHeading(formatMonthYear(context, month.month)),
                  style: heading,
                ),
                const Spacer(),
                // The weekdays, over the facade's columns.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _Facade.side),
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: _Facade.gap),
                        SizedBox(
                          width: _Facade.window,
                          child: Text(
                            narrow[(firstDay + i) % 7],
                            textAlign: TextAlign.center,
                            style: type.label,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _Facade(month: month, cells: cells, weeks: weeks),
                // The street the building stands on.
                const Divider(height: 1.5, thickness: 1.5, color: Palette.line),
                const SizedBox(height: 20),
                Text(
                  l10n.cardMonthLit(month.count),
                  style: type.body.copyWith(
                    color: Palette.paper,
                    fontSize: fa ? 17 : 18,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final t in const [0.15, 0.55, 1.0]) ...[
                      _Glass(color: _lit(t), size: const Size(10, 12)),
                      const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 4),
                    Text(l10n.cardMonthLegend, style: type.label),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A lit Window's glass for a night [t] of the way to the month's
/// brightest: a low amber at the dimmest, the user's own warm light at the
/// brightest.
Color _lit(double t) =>
    Color.lerp(const Color(0xFF9A6B24), Palette.me, math.sqrt(t.clamp(0, 1)))!;

/// The building: a wall with a floor per week, a Window per night.
class _Facade extends StatelessWidget {
  const _Facade({
    required this.month,
    required this.cells,
    required this.weeks,
  });

  final ReadingMonth month;

  /// The nights in grid order, with nulls for the days before the first.
  final List<DateTime?> cells;
  final int weeks;

  static const window = 30.0;
  static const gap = 11.5;
  static const side = 16.0;
  static const floor = 40.0;
  static const floorGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final most = month.most;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Palette.wall,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        border: Border(top: BorderSide(color: Palette.raise, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(side, 16, side, 16),
        child: Column(
          children: [
            for (var w = 0; w < weeks; w++) ...[
              if (w > 0) const SizedBox(height: floorGap),
              Row(
                children: [
                  for (var d = 0; d < 7; d++) ...[
                    if (d > 0) const SizedBox(width: gap),
                    _night(
                      w * 7 + d < cells.length ? cells[w * 7 + d] : null,
                      most,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _night(DateTime? night, Duration most) {
    const size = Size(window, floor);
    if (night == null) return const SizedBox(width: window, height: floor);
    if (night.isAfter(month.tonight)) {
      return const _Glass(color: Palette.newFloor, size: size);
    }
    if (!month.isLit(night)) {
      return const _Glass(color: Palette.unlit, size: size);
    }
    final t = most == Duration.zero
        ? 0.3
        : month.readingOn(night).inSeconds / most.inSeconds;
    return _Glass(color: _lit(t), size: size, glow: 0.15 + 0.45 * t);
  }
}

/// One pane of glass, lit or not; a lit one throws a little light.
class _Glass extends StatelessWidget {
  const _Glass({required this.color, required this.size, this.glow = 0});

  final Color color;
  final Size size;
  final double glow;

  @override
  Widget build(BuildContext context) => Container(
    width: size.width,
    height: size.height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2.5),
      boxShadow: [
        if (glow > 0)
          BoxShadow(
            color: Palette.lamp.withValues(alpha: glow),
            blurRadius: 14,
          ),
      ],
    ),
  );
}
