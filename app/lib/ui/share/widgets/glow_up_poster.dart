import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/building/widgets/longest_stretch_trend.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// The attention glow-up: the first Longest stretch and the one now, at
/// the two ends of the line it rose along. The user is only ever compared
/// with themselves, so there's no one else on it.
///
/// The line itself joins "then" to "now", so no arrow is needed. In Persian
/// it runs right to left, like the Road and the trend on the Building.
class GlowUpPoster extends StatelessWidget {
  const GlowUpPoster({required this.rises, required this.watched, super.key});

  /// From [longestStretchTrend], oldest first, with at least two evenings.
  final List<StretchRise> rises;

  /// Whether it's the Longest stretch for watching rather than reading.
  final bool watched;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fa = isPersian(context);
    final type = PosterType(fa: fa);
    final first = rises.first;
    final last = rises.last;
    final then = type.ui(fa ? 22 : 24, Palette.soft, FontWeight.w500);
    final now = type
        .book(fa ? 54 : 60, Palette.me, FontWeight.w600)
        .copyWith(
          height: 1.1,
          shadows: [
            Shadow(color: Palette.lamp.withValues(alpha: 0.6), blurRadius: 24),
          ],
        );

    return PosterFrame(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              l10n.cardGlowUpHeading,
              style: type.title.copyWith(fontSize: fa ? 28 : 30),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.cardGlowUpWhat(watched ? 'watching' : 'reading'),
              style: type.body.copyWith(color: Palette.mute),
            ),
            const Spacer(),
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: TrendLinePainter(
                  rises,
                  Directionality.of(context),
                  stroke: 3.5,
                  dot: 4,
                  now: 8,
                  glow: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _End(
                  label: l10n.cardGlowUpFirst,
                  minutes: l10n.minutesShort(first.longest.inMinutes),
                  date: formatDayMonth(context, first.evening),
                  number: then,
                  type: type,
                ),
                const Spacer(),
                _End(
                  label: l10n.cardGlowUpNow,
                  minutes: l10n.minutesShort(last.longest.inMinutes),
                  date: formatDayMonth(context, last.evening),
                  number: now,
                  type: type,
                  end: true,
                ),
              ],
            ),
            const Spacer(),
            Text(
              l10n.cardGlowUpSelf,
              style: type.body.copyWith(color: Palette.paper),
            ),
          ],
        ),
      ),
    );
  }
}

/// One end of the line: what it was, how long, and the evening.
class _End extends StatelessWidget {
  const _End({
    required this.label,
    required this.minutes,
    required this.date,
    required this.number,
    required this.type,
    this.end = false,
  });

  final String label;
  final String minutes;
  final String date;
  final TextStyle number;
  final PosterType type;

  /// The end of the line, now: aligned to the far edge.
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(label, style: type.label),
      Text(minutes, style: number),
      Text(date, style: type.label),
    ],
  );
}
