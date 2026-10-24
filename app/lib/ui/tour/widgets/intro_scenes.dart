import 'dart:math' as math;

import 'package:doomread/ui/core/empty_scenes.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// The intro's first card: movie night, seen from behind the sofa. Three
/// friends, a film on the screen (a desert at dusk, for Paris, Texas) and a
/// phone face down on the arm, untouched. The film comes on with the light.
class MovieNightPainter extends ScenePainter {
  MovieNightPainter(super.light, {required super.rtl});

  static const _skyTop = Color(0xFF2E4473);
  static const _dusk = Color(0xFFE0895A);
  static const _desert = Color(0xFF6E4B33);

  @override
  Size get frame => const Size(240, 150);

  @override
  void draw(Canvas canvas, double on) {
    const screen = Rect.fromLTRB(62, 12, 178, 80);
    // The film's light fills the room.
    sceneGlow(canvas, const Offset(120, 62), 60, 0.2 * on);
    canvas
      // The stand under the screen, then the screen's bezel.
      ..drawRect(const Rect.fromLTRB(96, 80, 144, 86), sceneFill(Palette.deep))
      ..drawRRect(
        RRect.fromRectAndRadius(screen.inflate(3), const Radius.circular(3)),
        sceneFill(Palette.deep),
      )
      ..save()
      ..clipRect(screen)
      ..drawRect(
        screen,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(Palette.unlit, _skyTop, on)!,
              Color.lerp(Palette.unlit, _dusk, on)!,
            ],
          ).createShader(screen),
      )
      // The sun going down behind the horizon.
      ..drawCircle(
        const Offset(140, 60),
        9,
        sceneFill(Color.lerp(Palette.unlit, Palette.me, on)!),
      )
      ..drawRect(
        const Rect.fromLTRB(62, 60, 178, 80),
        sceneFill(Color.lerp(Palette.deep, _desert, on)!),
      )
      // A lone telegraph pole and its wire, going off into the desert.
      ..drawRect(
        const Rect.fromLTWH(86, 36, 1.6, 24),
        sceneFill(Palette.deep.withValues(alpha: 0.8 * on)),
      )
      ..drawRect(
        const Rect.fromLTWH(82, 39, 10, 1.2),
        sceneFill(Palette.deep.withValues(alpha: 0.8 * on)),
      )
      ..drawLine(
        const Offset(87, 40),
        const Offset(178, 52),
        Paint()
          ..color = Palette.deep.withValues(alpha: 0.5 * on)
          ..strokeWidth = 0.6,
      )
      ..restore()
      // The sofa's arms.
      ..drawRRect(
        RRect.fromLTRBR(16, 104, 46, 150, const Radius.circular(6)),
        sceneFill(Palette.raise),
      )
      ..drawRRect(
        RRect.fromLTRBR(194, 104, 224, 150, const Radius.circular(6)),
        sceneFill(Palette.raise),
      );

    // Three friends, lit at the edges by the film.
    for (final x in [82.0, 120.0, 158.0]) {
      _friend(canvas, x, on, tall: x == 120);
    }

    canvas
      ..drawRRect(
        RRect.fromLTRBR(36, 118, 204, 150, const Radius.circular(8)),
        sceneFill(Palette.wall),
      )
      ..drawRect(
        const Rect.fromLTWH(40, 118, 160, 2),
        sceneFill(Color.lerp(Palette.line, Palette.tickPassed, 0.35 * on)!),
      )
      // The phone, face down on the arm, where it stays all film.
      ..drawRRect(
        RRect.fromLTRBR(20, 100, 40, 104, const Radius.circular(1.5)),
        sceneFill(Palette.indicator),
      )
      ..drawRect(
        const Rect.fromLTWH(22, 100, 16, 0.8),
        sceneFill(Palette.mute.withValues(alpha: 0.5)),
      );

    // A bowl of popcorn on the other arm.
    final kernel = sceneFill(Color.lerp(Palette.soft, Palette.paper, on)!);
    for (final (x, y) in [
      (203.0, 99.0),
      (208.0, 97.0),
      (213.0, 99.0),
      (206.0, 101.0),
      (211.0, 101.5),
    ]) {
      canvas.drawCircle(Offset(x, y), 2.6, kernel);
    }
    canvas.drawPath(
      Path()
        ..moveTo(198, 101)
        ..lineTo(218, 101)
        ..quadraticBezierTo(216, 106, 208, 106)
        ..quadraticBezierTo(200, 106, 198, 101)
        ..close(),
      sceneFill(Color.lerp(Palette.indicator, const Color(0xFFB9584A), on)!),
    );
  }

  /// One friend from behind: head and shoulders, with a rim of film light.
  void _friend(Canvas canvas, double x, double on, {required bool tall}) {
    final top = tall ? 86.0 : 90.0;
    final rim = sceneFill(
      Color.lerp(Palette.deep, Palette.tickPassed, 0.7 * on)!,
    );
    final body = sceneFill(Palette.deep);
    final shoulders = RRect.fromLTRBR(
      x - 19,
      top + 20,
      x + 19,
      top + 48,
      const Radius.circular(14),
    );
    canvas
      ..drawRRect(shoulders.shift(const Offset(0, -1.4)), rim)
      ..drawCircle(Offset(x, top + 7.6), 10.4, rim)
      ..drawRRect(shoulders, body)
      ..drawCircle(Offset(x, top + 9), 10.4, body);
  }
}

/// The intro's second card: the House at night, its Windows coming on one
/// after another, and the user's own, warmest, last.
class CompanyPainter extends ScenePainter {
  CompanyPainter(super.light, {required super.rtl});

  /// Which panes come on, in order, by (row, column); the user's is last.
  static const _order = [
    (2, 0),
    (0, 3),
    (1, 1),
    (2, 4),
    (0, 0),
    (1, 4),
    (2, 2),
    (0, 2),
  ];
  static const _mine = (1, 2);

  @override
  Size get frame => const Size(240, 150);

  @override
  void draw(Canvas canvas, double on) {
    final star = sceneFill(Palette.mute.withValues(alpha: 0.45));
    for (final (x, y, r) in [
      (16.0, 20.0, 0.9),
      (48.0, 8.0, 0.7),
      (188.0, 12.0, 0.7),
      (222.0, 46.0, 0.8),
    ]) {
      canvas.drawCircle(Offset(x, y), r, star);
    }
    canvas
      ..drawCircle(
        const Offset(206, 22),
        9,
        sceneFill(Palette.paper.withValues(alpha: 0.9)),
      )
      ..drawCircle(const Offset(210, 19), 8, sceneFill(Palette.night))
      // Neighbouring blocks, dark.
      ..drawRect(const Rect.fromLTWH(0, 84, 30, 66), sceneFill(Palette.deep))
      ..drawRect(const Rect.fromLTWH(212, 74, 28, 76), sceneFill(Palette.deep))
      // The House: chimney, wall, the roof ledge.
      ..drawRect(const Rect.fromLTWH(70, 18, 12, 14), sceneFill(Palette.wall))
      ..drawRect(const Rect.fromLTWH(36, 28, 168, 122), sceneFill(Palette.wall))
      ..drawRect(
        const Rect.fromLTWH(32, 26, 176, 5),
        sceneFill(Palette.newFloor),
      );

    // Each pane's moment comes in turn; the user's is the last beat.
    final beats = _order.length + 1;
    double lit(int i) => ((on * beats - i) / 1.6).clamp(0.0, 1.0);

    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 5; c++) {
        final pane = Rect.fromLTWH(50.0 + c * 30, 42.0 + r * 34, 18, 22);
        final i = _order.indexOf((r, c));
        if ((r, c) == _mine) {
          _mineAt(canvas, pane, lit(_order.length));
        } else {
          _pane(canvas, pane, i < 0 ? 0 : lit(i));
        }
      }
    }
  }

  void _sill(Canvas canvas, Rect pane) => canvas.drawRect(
    Rect.fromLTWH(pane.left - 2, pane.bottom + 1, pane.width + 4, 2),
    sceneFill(Palette.raise),
  );

  void _pane(Canvas canvas, Rect pane, double on) {
    final rounded = RRect.fromRectAndRadius(pane, const Radius.circular(1.5));
    if (on > 0) sceneGlow(canvas, pane.center, 16, 0.16 * on);
    canvas.drawRRect(
      rounded,
      sceneFill(Color.lerp(Palette.unlit, Palette.lamp, on * 0.85)!),
    );
    _sill(canvas, pane);
    canvas.drawRect(
      Rect.fromLTWH(pane.center.dx - 0.5, pane.top, 1, pane.height),
      sceneFill(Palette.wall),
    );
  }

  /// The user's Window: a lamp inside, coming on warmer than the rest.
  void _mineAt(Canvas canvas, Rect pane, double on) {
    final rounded = RRect.fromRectAndRadius(pane, const Radius.circular(1.5));
    sceneGlow(canvas, pane.center, 26, 0.32 * on);
    canvas.drawRRect(
      rounded,
      sceneFill(Color.lerp(Palette.unlit, Palette.me, on)!),
    );
    _sill(canvas, pane);
    final ink = sceneFill(
      Color.lerp(Palette.indicator, Palette.tickPassed, on)!,
    );
    final x = pane.left;
    final y = pane.top;
    canvas
      ..drawPath(
        Path()
          ..moveTo(x + 6, y + 6)
          ..lineTo(x + 11, y + 6)
          ..lineTo(x + 13.5, y + 11.5)
          ..lineTo(x + 3.5, y + 11.5)
          ..close(),
        ink,
      )
      ..drawRect(Rect.fromLTWH(x + 8, y + 11.5, 1.2, 6.5), ink)
      ..drawRRect(
        RRect.fromLTRBR(
          x + 5,
          y + 18,
          x + 12.2,
          y + 19.6,
          const Radius.circular(0.8),
        ),
        ink,
      )
      ..drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Palette.lamp.withValues(alpha: math.max(0.3, on)),
      );
  }
}
