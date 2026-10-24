import 'dart:math' as math;

import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// The fixed canvas every share card is laid out on, whatever the device:
/// 360×640 logical pixels, drawn at three times that for a 1080×1920 story.
/// The system's font scale and bold text don't reach it, so the image is
/// the same on every phone.
class PosterCanvas extends StatelessWidget {
  const PosterCanvas({required this.child, super.key});

  /// The canvas, in logical pixels; the image is three times this.
  static const size = Size(360, 640);

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: const MediaQueryData(
      size: size,
      textScaler: TextScaler.noScaling,
      disableAnimations: true,
    ),
    child: SizedBox.fromSize(
      size: size,
      child: Material(
        type: MaterialType.transparency,
        child: ClipRect(child: child),
      ),
    ),
  );
}

/// Whether [context] is in Persian, which gets its own layout on a card.
bool isPersian(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'fa';

/// The cards' type, set apart from the app theme so it can't drift with
/// it. Persian has its own faces and taller lines, and no letter spacing.
class PosterType {
  PosterType({required this.fa})
    : finished = TextStyle(
        fontSize: fa ? 21 : 22,
        height: fa ? 1.7 : 1.35,
        fontWeight: FontWeight.w400,
        fontVariations: const [FontVariation.weight(400)],
        color: Palette.soft,
      ),
      title = _book(fa, fa ? 30 : 32, Palette.paper, FontWeight.w600),
      author = _ui(fa, 14, Palette.mute, FontWeight.w400),
      body = _ui(fa, 15, Palette.soft, FontWeight.w400),
      number = TextStyle(
        fontFamily: fa ? 'VazirmatnUI' : 'Literata',
        fontFamilyFallback: [if (fa) 'BricolageGrotesque' else 'VazirmatnUI'],
        fontSize: fa ? 26 : 28,
        height: 1.25,
        fontWeight: fa ? FontWeight.w700 : FontWeight.w500,
        fontVariations: fa ? null : const [FontVariation.weight(500)],
        letterSpacing: 0,
        color: Palette.me,
      ),
      label = _ui(fa, 13, Palette.mute, FontWeight.w400),
      note = TextStyle(
        fontFamily: fa ? 'NotoNaskhArabic' : 'Literata',
        fontFamilyFallback: [if (fa) 'Literata' else 'NotoNaskhArabic'],
        fontSize: fa ? 16 : 17,
        height: fa ? 1.85 : 1.5,
        letterSpacing: 0,
        color: Palette.paper,
      ),
      mark = _ui(fa, 14, Palette.paper, FontWeight.w500);

  final bool fa;

  /// "I finished", the quiet first line of the title's heading.
  final TextStyle finished;
  final TextStyle title;
  final TextStyle author;
  final TextStyle body;
  final TextStyle number;
  final TextStyle label;
  final TextStyle note;
  final TextStyle mark;

  /// The interface face: Bricolage Grotesque, or Vazirmatn UI in Persian.
  TextStyle ui(double size, Color color, [FontWeight w = FontWeight.w400]) =>
      _ui(fa, size, color, w);

  /// The book face, for titles and Notes: Literata, or Naskh in Persian.
  TextStyle book(double size, Color color, [FontWeight w = FontWeight.w400]) =>
      _book(fa, size, color, w);

  static TextStyle _ui(bool fa, double size, Color color, FontWeight w) =>
      TextStyle(
        fontFamily: fa ? 'VazirmatnUI' : 'BricolageGrotesque',
        fontFamilyFallback: [if (fa) 'BricolageGrotesque' else 'VazirmatnUI'],
        fontSize: size,
        height: fa ? 1.7 : 1.4,
        fontWeight: w,
        fontVariations: [FontVariation.weight(w.value.toDouble())],
        letterSpacing: 0,
        color: color,
      );

  static TextStyle _book(bool fa, double size, Color color, FontWeight w) =>
      TextStyle(
        fontFamily: fa ? 'NotoNaskhArabic' : 'Literata',
        fontFamilyFallback: [if (fa) 'Literata' else 'NotoNaskhArabic'],
        fontSize: size,
        height: fa ? 1.55 : 1.15,
        fontWeight: w,
        fontVariations: [FontVariation.weight(w.value.toDouble())],
        letterSpacing: 0,
        color: color,
      );
}

/// A small lit window and the app's name: the icon, in words.
class Wordmark extends StatelessWidget {
  const Wordmark(this.name, this.style, {super.key});

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 12,
        decoration: BoxDecoration(
          color: Palette.lamp,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: [
            BoxShadow(
              color: Palette.lamp.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(name, style: style),
    ],
  );
}

/// The night: deep at the top, a little lighter lower down, with a few
/// stars. They're placed by a fixed seed, so every card has the same.
class PosterSky extends CustomPainter {
  const PosterSky({this.stars = 46, this.starDepth = 0.42});

  /// How many stars, and how far down the sky they reach, as a share of
  /// its height.
  final int stars;
  final double starDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.zenith, Palette.deep, Palette.night],
          stops: [0, 0.35, 0.62],
        ).createShader(rect),
    );
    final random = math.Random(1980);
    final star = Paint();
    for (var i = 0; i < stars; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        24 + random.nextDouble() * size.height * starDepth,
      );
      final r = 0.5 + random.nextDouble() * 0.9;
      star.color = Palette.paper.withValues(
        alpha: 0.25 + random.nextDouble() * 0.5,
      );
      canvas.drawCircle(at, r, star);
    }
  }

  @override
  bool shouldRepaint(PosterSky old) =>
      old.stars != stars || old.starDepth != starDepth;
}

/// Lamplight pooling at [at] (a fraction of the card): a warm, wide,
/// faint glow, as if a window were just out of frame.
class LampGlow extends CustomPainter {
  const LampGlow({this.at = const Offset(0.5, 0.3), this.reach = 260});

  final Offset at;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(at.dx * size.width, at.dy * size.height);
    canvas.drawCircle(
      c,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Palette.lamp.withValues(alpha: 0.16),
            Palette.lamp.withValues(alpha: 0.05),
            Palette.lamp.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: reach)),
    );
  }

  @override
  bool shouldRepaint(LampGlow old) => old.at != at || old.reach != reach;
}
