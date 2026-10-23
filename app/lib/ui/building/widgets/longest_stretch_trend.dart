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
  const LongestStretchTrend({required this.rises, super.key});

  final List<StretchRise> rises;

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
    return Semantics(
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
              painter: _TrendPainter(rises, Directionality.of(context)),
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
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.rises, this.direction);

  final List<StretchRise> rises;
  final TextDirection direction;

  static const _dot = 3.0;
  static const _now = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final start = rises.first.evening;
    final days = rises.last.evening.difference(start).inHours / 24;
    final top = rises.last.longest.inSeconds;
    final width = size.width - 2 * _now;
    final height = size.height - 2 * _now;
    Offset at(StretchRise r) {
      // A single evening sits at the end, where the line would arrive.
      final t = days == 0
          ? 1.0
          : r.evening.difference(start).inHours / 24 / days;
      final x = _now + width * (direction == TextDirection.rtl ? 1 - t : t);
      return Offset(x, _now + height * (1 - r.longest.inSeconds / top));
    }

    final base = size.height - _now;
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = Palette.line
        ..strokeWidth = 1,
    );
    final points = rises.map(at).toList();
    final lamp = Paint()..color = Palette.lamp;
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..color = Palette.lamp
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (final p in points.take(points.length - 1)) {
      canvas.drawCircle(p, _dot, lamp);
    }
    canvas.drawCircle(points.last, _now, Paint()..color = Palette.me);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.rises != rises || old.direction != direction;
}
