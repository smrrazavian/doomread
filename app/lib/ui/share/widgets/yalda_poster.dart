import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/yalda.dart';
import 'package:doomread/ui/reading/widgets/house_view.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
import 'package:doomread/ui/share/widgets/share_preview_screen.dart';
import 'package:doomread/ui/share/yalda_night.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Whether [night] has a poster yet: something was read tonight, and
/// this platform can share.
bool canShareYalda(BuildContext context, YaldaNight night) =>
    night.work != null && night.minutes > 0 && canShare(context);

/// Opens the Yalda poster for [night], which [canShareYalda], in the share
/// preview every card uses.
Future<void> showYaldaPoster(BuildContext context, YaldaNight night) =>
    openSharePreview(
      context,
      YaldaPoster(
        work: night.work!,
        minutes: night.minutes,
        house: night.house,
        evening: night.evening,
      ),
    );

/// Shab-e Yalda as a story-sized card: the House in Yalda light, the
/// user's own Window up close with the Yalda table in it, what they read,
/// and for how long tonight. Laid out on the shared card frame, so Persian
/// gets its own layout: right to left, Persian digits, Naskh for the title.
class YaldaPoster extends StatelessWidget {
  const YaldaPoster({
    required this.work,
    required this.minutes,
    required this.house,
    required this.evening,
    super.key,
  });

  /// What was read tonight; the last of it, if there was more than one.
  final Work work;

  /// Tonight's reading, in whole minutes.
  final int minutes;

  /// The House's Windows, from the journal.
  final List<HouseWindow> house;

  /// Tonight, for the year on the date line.
  final DateTime evening;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fa = isPersian(context);
    final type = PosterType(fa: fa);
    // Persian counts years from the Hijra, as Yalda itself does.
    final year = NumberFormat(
      '0',
      locale.languageCode,
    ).format(fa ? toSolarHijri(evening).year : evening.year);

    return PosterFrame(
      // The longest night has more stars than most.
      sky: const PosterSky(stars: 70, starDepth: 0.36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The House across the way, then the user's own Window up close.
          // A long title shrinks the scene rather than overflowing.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  // Its foot lost in the night.
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.transparent],
                      stops: [0.7, 1],
                    ).createShader(rect),
                    child: SizedBox(
                      width: 270,
                      child: HouseView(
                        windows: house,
                        kind: work.kind,
                        yalda: true,
                        caption: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: _HeroWindow.width,
                    height: _HeroWindow.height,
                    child: CustomPaint(
                      painter: _HeroWindow(
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.yaldaPosterHeading(work.kind.name),
            style: type.finished.copyWith(fontSize: fa ? 19 : 20),
          ),
          WorkByline(
            work: work,
            title: type.book(fa ? 27 : 29, Palette.paper, FontWeight.w600),
            author: type.author,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                formatNumber(minutes, locale),
                style: type.number.copyWith(
                  fontSize: fa ? 36 : 40,
                  height: 1.1,
                  color: YaldaPalette.me,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.yaldaPosterMinutes(minutes), style: type.label),
                    Text(l10n.yaldaPosterNight(year), style: type.label),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The user's own Window up close, the hero: a Persian arch lit warm, a
/// lamp and the Divan of Hafez open on its stand inside, and on the sill
/// half a pomegranate, a slice of watermelon and a whole pomegranate. It's
/// drawn from the start side and flipped for right to left, like the House.
class _HeroWindow extends CustomPainter {
  const _HeroWindow({required this.rtl});

  final bool rtl;

  static const width = 210.0;
  static const height = 200.0;

  /// The scene's own units, scaled to fit.
  static const _w = 180.0;

  /// Where the glass ends and the sill begins.
  static const _sill = 160.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / _w;
    canvas.save();
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas
      ..translate(0, size.height - 172 * s)
      ..scale(s);
    _paint(canvas);
    canvas.restore();
  }

  void _paint(Canvas canvas) {
    final arch = Path()
      ..moveTo(28, _sill)
      ..lineTo(28, 56)
      ..cubicTo(28, 30, 70, 22, 90, 4)
      ..cubicTo(110, 22, 152, 30, 152, 56)
      ..lineTo(152, _sill)
      ..close();
    final glass = arch.getBounds();
    // The light on the night around it: a wide crimson-amber halo.
    canvas
      ..drawCircle(
        const Offset(90, 90),
        120,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  YaldaPalette.ember.withValues(alpha: 0.32),
                  YaldaPalette.ember.withValues(alpha: 0.1),
                  YaldaPalette.ember.withValues(alpha: 0),
                ],
                stops: const [0, 0.5, 1],
              ).createShader(
                Rect.fromCircle(center: const Offset(90, 90), radius: 120),
              ),
      )
      ..drawPath(
        arch,
        Paint()
          ..color = YaldaPalette.ember.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      // The glass, lamplit: paler up top, warmer toward the table.
      ..drawPath(
        arch,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [YaldaPalette.me, YaldaPalette.lamp],
          ).createShader(glass),
      );
    _lattice(canvas);
    _lamp(canvas);
    _divan(canvas);
    canvas
      // The frame, and the sill across the bottom.
      ..drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.wall,
      )
      ..drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = YaldaPalette.outline.withValues(alpha: 0.5),
      )
      ..drawRRect(
        RRect.fromLTRBR(14, _sill, 166, _sill + 9, const Radius.circular(2)),
        Paint()..color = YaldaPalette.sill,
      )
      ..drawRect(
        const Rect.fromLTWH(14, _sill, 152, 1.2),
        Paint()..color = YaldaPalette.lamp.withValues(alpha: 0.5),
      );
    // The Yalda table, on the sill in front of the glass.
    paintPomegranate(canvas, const Offset(24, _sill), 7.5);
    paintWatermelon(canvas, const Offset(116, _sill), 26);
    paintPomegranateHalf(canvas, const Offset(148, _sill - 12), 12);
  }

  /// A shamseh, the eight-pointed star of Persian windows, in the arch
  /// above a transom bar.
  void _lattice(Canvas canvas) {
    final bar = Paint()
      ..color = Palette.wall.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawLine(const Offset(28, 58), const Offset(152, 58), bar);
    const c = Offset(90, 36);
    const r = 10.0;
    // Sixteen points, alternately out and in: the star's tips and notches.
    final star = Path()
      ..addPolygon([
        for (var k = 0; k < 16; k++)
          c +
              Offset.fromDirection(
                -math.pi / 2 + k * math.pi / 8,
                k.isEven ? r : r * 0.62,
              ),
      ], true);
    canvas
      ..drawPath(star, Paint()..color = Palette.wall.withValues(alpha: 0.85))
      ..drawCircle(c, r * 0.3, Paint()..color = YaldaPalette.lamp);
  }

  /// A reading lamp in shadow against the glass, with its pool of light.
  void _lamp(Canvas canvas) {
    final ink = Paint()..color = Palette.deep.withValues(alpha: 0.82);
    canvas
      ..drawCircle(
        const Offset(52, 104),
        16,
        Paint()
          ..color = Palette.paper.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      )
      ..drawPath(
        Path()
          ..moveTo(44, 74)
          ..lineTo(60, 74)
          ..lineTo(68, 96)
          ..lineTo(36, 96)
          ..close(),
        ink,
      )
      ..drawRect(const Rect.fromLTWH(50.5, 96, 3, 58), ink)
      ..drawRRect(
        RRect.fromLTRBR(40, 154, 64, _sill, const Radius.circular(1.5)),
        ink,
      );
  }

  /// The Divan of Hafez, open on a rahl, the folding stand it's read from:
  /// its pages catch the lamp, with lines of verse on them.
  void _divan(Canvas canvas) {
    final ink = Paint()
      ..color = Palette.deep.withValues(alpha: 0.82)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    // The stand's crossed legs.
    canvas
      ..drawLine(const Offset(84, 132), const Offset(112, _sill - 1), ink)
      ..drawLine(const Offset(112, 132), const Offset(84, _sill - 1), ink);
    // The covers, a little wider than the pages, then the pages.
    final covers = Path()
      ..moveTo(98, 136)
      ..lineTo(72, 126)
      ..lineTo(72, 104)
      ..lineTo(98, 113)
      ..lineTo(124, 104)
      ..lineTo(124, 126)
      ..close();
    final pages = Path()
      ..moveTo(98, 133)
      ..lineTo(75, 124)
      ..lineTo(75, 105)
      ..lineTo(98, 113.5)
      ..lineTo(121, 105)
      ..lineTo(121, 124)
      ..close();
    canvas
      ..drawPath(covers, Paint()..color = YaldaPalette.rindShade)
      ..drawPath(pages, Paint()..color = YaldaPalette.pith)
      ..drawLine(
        const Offset(98, 113.5),
        const Offset(98, 133),
        Paint()
          ..color = YaldaPalette.rindShade.withValues(alpha: 0.5)
          ..strokeWidth = 0.8,
      );
    // Lines of verse, two short half-lines a row, as a Divan is set.
    final verse = Paint()
      ..color = Palette.deep.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final dy = 111.0 + i * 5;
      for (final (x0, x1, side) in const [
        (78.0, 86.0, -1),
        (88.0, 95.0, -1),
        (101.0, 108.0, 1),
        (110.0, 118.0, 1),
      ]) {
        // Each page slopes up toward its outer edge.
        double y(double x) => dy + (side < 0 ? (x - 98) : (98 - x)) * -0.37;
        canvas.drawLine(Offset(x0, y(x0)), Offset(x1, y(x1)), verse);
      }
    }
  }

  @override
  bool shouldRepaint(_HeroWindow oldDelegate) => oldDelegate.rtl != rtl;
}
