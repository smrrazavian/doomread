import 'dart:math' as math;

import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Debug builds only: run with `--dart-define=DOOMREAD_YALDA=true` and every
/// night is Yalda, so it can be seen before 30 Azar. Release and profile
/// builds compile it out, and the clock is never faked, so the journal's
/// times stay true.
const bool _alwaysYalda = kDebugMode && bool.fromEnvironment('DOOMREAD_YALDA');

/// Whether [now] is Shab-e Yalda (see [isYalda]). Every screen asks here.
bool yaldaAt(DateTime now) => _alwaysYalda || isYalda(now);

/// Yalda's colours, all in one place: the lamp turned toward candle and
/// pomegranate, and what's on the Yalda table. See the design, section 8.
abstract final class YaldaPalette {
  /// The user's Window: a warmer lamp, its glow, and the outline.
  static const lamp = Color(0xFFF5A25A);
  static const me = Color(0xFFFFCF94);
  static const outline = Color(0xFFFFEBD2);

  /// The crimson-amber halo every lit Window throws on the longest night.
  static const ember = Color(0xFFEC6A3E);

  /// A past evening's Window, amber at the top and crimson at the sill;
  /// still never as bright as the user's own.
  static const pastTop = Color(0xFFD8853F);
  static const pastBottom = Color(0xFFA83A3A);

  /// Earlier tonight's outline.
  static const earlierOutline = Color(0xFFF08A5A);

  /// The windowsills the pomegranates sit on.
  static const sill = Color(0xFF3A4672);

  /// A pomegranate: its rind, the shade on its far side and crown, and the
  /// seeds and pith of a cut half.
  static const rind = Color(0xFFC4384A);
  static const rindShade = Color(0xFF8A2236);
  static const seed = Color(0xFFE8566A);
  static const pith = Color(0xFFF6DCC8);
  static const bed = Color(0xFF6E1A2A);

  /// A slice of watermelon: rind, its pale inner edge, flesh and pips.
  static const melonRind = Color(0xFF3F7B4C);
  static const melonPale = Color(0xFFCFE3B0);
  static const melon = Color(0xFFE5485C);
  static const pip = Color(0xFF2A1A20);
}

/// A whole pomegranate standing at [base], [r] round: shaded rind, a glint
/// and its crown, flared so it reads even small. Symmetric, so it reads the
/// same mirrored.
void paintPomegranate(Canvas canvas, Offset base, double r) {
  final c = base.translate(0, -r);
  final body = Rect.fromCircle(center: c, radius: r);
  canvas
    ..drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [
            YaldaPalette.seed,
            YaldaPalette.rind,
            YaldaPalette.rindShade,
          ],
          stops: [0, 0.55, 1],
        ).createShader(body),
    )
    ..drawPath(
      Path()
        ..moveTo(c.dx - r * 0.34, c.dy - r * 0.86)
        ..lineTo(c.dx - r * 0.62, c.dy - r * 1.5)
        ..lineTo(c.dx - r * 0.24, c.dy - r * 1.22)
        ..lineTo(c.dx, c.dy - r * 1.62)
        ..lineTo(c.dx + r * 0.24, c.dy - r * 1.22)
        ..lineTo(c.dx + r * 0.62, c.dy - r * 1.5)
        ..lineTo(c.dx + r * 0.34, c.dy - r * 0.86)
        ..close(),
      Paint()..color = YaldaPalette.rindShade,
    )
    ..drawCircle(
      c.translate(-r * 0.38, -r * 0.4),
      r * 0.22,
      Paint()..color = Palette.paper.withValues(alpha: 0.55),
    );
}

/// Half a pomegranate, cut side up, its cut across [center]: rind, a rim of
/// pith, and ruby seeds. [opacity] fades it in with a Window's light.
void paintPomegranateHalf(
  Canvas canvas,
  Offset center,
  double r, {
  double opacity = 1,
}) {
  Paint fill(Color c) => Paint()..color = c.withValues(alpha: c.a * opacity);
  // The rind's bowl, then the cut face seen a little from above: a thin
  // rim of pith around a bed of seeds.
  final face = Rect.fromCenter(center: center, width: 2 * r, height: 0.8 * r);
  canvas
    ..drawArc(
      Rect.fromCircle(center: center, radius: r),
      0,
      math.pi,
      true,
      fill(YaldaPalette.rind),
    )
    ..drawArc(
      Rect.fromCircle(center: center, radius: r).deflate(r * 0.08),
      math.pi * 0.08,
      math.pi * 0.5,
      false,
      fill(YaldaPalette.rindShade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16,
    )
    ..drawOval(face, fill(YaldaPalette.pith))
    ..drawOval(face.deflate(r * 0.1), fill(YaldaPalette.bed));
  // The seeds, packed in their chambers; placed by hand, the same every time.
  final seed = fill(YaldaPalette.seed);
  final glint = fill(Palette.paper.withValues(alpha: 0.7));
  for (final (dx, dy) in const [
    (-0.62, 0.0),
    (-0.4, -0.18),
    (-0.38, 0.16),
    (-0.14, -0.04),
    (0.1, -0.2),
    (0.08, 0.17),
    (0.34, -0.02),
    (0.58, -0.08),
    (0.52, 0.14),
  ]) {
    final at = center.translate(dx * r, dy * r);
    canvas
      ..drawCircle(at, r * 0.12, seed)
      ..drawCircle(at.translate(-r * 0.04, -r * 0.04), r * 0.035, glint);
  }
}

/// A slice of watermelon standing on its rind at [base], [r] from tip to
/// rind: a wedge of red flesh with a few black pips. Symmetric, so it
/// mirrors cleanly.
void paintWatermelon(Canvas canvas, Offset base, double r) {
  // The tip of the wedge points up; the rind is an arc along the bottom.
  final tip = base.translate(0, -r);
  final circle = Rect.fromCircle(center: tip, radius: r);
  const half = 0.5; // half the wedge's angle, in radians
  Path wedge(double inset) {
    final rect = circle.deflate(inset);
    return Path()
      ..moveTo(tip.dx, tip.dy + inset * 1.4)
      ..arcTo(rect, math.pi / 2 + half, -2 * half, false)
      ..close();
  }

  canvas
    ..drawPath(wedge(0), Paint()..color = YaldaPalette.melonRind)
    ..drawPath(wedge(r * 0.1), Paint()..color = YaldaPalette.melonPale)
    ..drawPath(wedge(r * 0.17), Paint()..color = YaldaPalette.melon);
  final pip = Paint()..color = YaldaPalette.pip;
  for (final (dx, dy) in const [
    (0.0, 0.4),
    (-0.16, 0.62),
    (0.16, 0.62),
    (-0.3, 0.78),
    (0.0, 0.76),
    (0.3, 0.78),
  ]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: tip.translate(dx * r, dy * r),
        width: r * 0.06,
        height: r * 0.1,
      ),
      pip,
    );
  }
}

/// A painted pomegranate in a [size] box, never an emoji: whole, or cut in
/// half to show its seeds.
class Pomegranate extends StatelessWidget {
  const Pomegranate({this.size = 20, this.half = false, super.key});

  final double size;
  final bool half;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _PomegranatePainter(half: half)),
  );
}

class _PomegranatePainter extends CustomPainter {
  const _PomegranatePainter({required this.half});

  final bool half;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (half) {
      paintPomegranateHalf(canvas, Offset(s / 2, s * 0.44), s * 0.46);
    } else {
      paintPomegranate(canvas, Offset(s / 2, s * 0.96), s * 0.34);
    }
  }

  @override
  bool shouldRepaint(_PomegranatePainter old) => old.half != half;
}
