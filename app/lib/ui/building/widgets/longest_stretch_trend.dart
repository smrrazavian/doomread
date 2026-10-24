import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// How the Longest stretch has risen over time: a gently rising line, the
/// first and last evening under it, and a sentence that is also what screen
/// readers hear. In Persian the line runs right to left, like the Road.
class LongestStretchTrend extends StatelessWidget {
  /// [rises] come from [longestStretchTrend], oldest first.
  const LongestStretchTrend({required this.rises, this.onShare, super.key});

  final List<StretchRise> rises;

  /// Opens the glow-up card; offered only once the line has risen.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    if (rises.isEmpty) {
      return Text(l10n.stretchTrendEmpty, style: text.bodyMedium);
    }
    final first = rises.first;
    final last = rises.last;
    final from = first.longest.inMinutes;
    final to = last.longest.inMinutes;
    final sentence = from == to
        ? l10n.stretchTrendSoFar(to)
        : l10n.stretchTrendGrew(from, to);
    final dates = first.evening == last.evening
        ? null
        : (
            formatDayMonth(context, first.evening),
            formatDayMonth(context, last.evening),
          );
    final trend = Semantics(
      container: true,
      label: [
        sentence,
        if (dates case (final a, final b)) l10n.stretchTrendDates(a, b),
      ].join(' '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 96,
            child: CustomPaint(
              painter: TrendLinePainter(rises, Directionality.of(context)),
            ),
          ),
          if (dates case (final a, final b)) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(a, style: text.bodySmall),
                Text(b, style: text.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(sentence, style: text.bodyMedium),
        ],
      ),
    );
    final onShare = this.onShare;
    if (onShare == null || to <= from) return trend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        trend,
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, size: 18),
            label: Text(l10n.cardGlowUpAction),
          ),
        ),
      ],
    );
  }
}

/// The rising line of a Longest stretch trend, oldest evening at the start
/// (the right in Persian, like the Road), the Longest stretch now as a
/// brighter dot at the end. The glow-up card draws it larger with [glow].
class TrendLinePainter extends CustomPainter {
  TrendLinePainter(
    this.rises,
    this.direction, {
    this.stroke = 2,
    this.dot = 3,
    this.now = 5,
    this.glow = false,
  });

  /// From [longestStretchTrend], oldest first; never empty.
  final List<StretchRise> rises;
  final TextDirection direction;

  /// The line's width, the earlier evenings' dots and the dot for now.
  final double stroke;
  final double dot;
  final double now;

  /// Lamplight around the line and the dot for now.
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final start = rises.first.evening;
    final days = rises.last.evening.difference(start).inHours / 24;
    final top = rises.last.longest.inSeconds;
    final pad = glow ? now * 2 : now;
    final width = size.width - 2 * pad;
    final height = size.height - 2 * pad;
    Offset at(StretchRise r) {
      // A single evening sits at the end, where the line would arrive.
      final t = days == 0
          ? 1.0
          : r.evening.difference(start).inHours / 24 / days;
      final x = pad + width * (direction == TextDirection.rtl ? 1 - t : t);
      return Offset(x, pad + height * (1 - r.longest.inSeconds / top));
    }

    final base = size.height - pad;
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = Palette.line
        ..strokeWidth = 1,
    );
    final points = rises.map(at).toList();
    final line = Path()..addPolygon(points, false);
    if (glow) {
      canvas
        ..drawPath(
          line,
          Paint()
            ..color = Palette.lamp.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke * 3
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawCircle(
          points.last,
          now * 3.2,
          Paint()
            ..color = Palette.lamp.withValues(alpha: 0.55)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
    }
    final lamp = Paint()..color = Palette.lamp;
    canvas.drawPath(
      line,
      Paint()
        ..color = Palette.lamp
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (final p in points.take(points.length - 1)) {
      canvas.drawCircle(p, dot, lamp);
    }
    canvas.drawCircle(points.last, now, Paint()..color = Palette.me);
  }

  @override
  bool shouldRepaint(TrendLinePainter old) =>
      old.rises != rises ||
      old.direction != direction ||
      old.stroke != stroke ||
      old.dot != dot ||
      old.now != now ||
      old.glow != glow;
}
