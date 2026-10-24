import 'dart:math' as math;

import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// The little painted scenes over an empty screen, in the House's style:
/// night ink, lamplight, nothing fetched from the network.
enum EmptyScene {
  /// Tonight with nothing to read: the House with every Window dark, the
  /// user's own one waiting with its lamp off.
  darkWindow(_DarkWindowPainter.new),

  /// The Library with nothing in it: a bare shelf under a lamp.
  emptyShelf(_EmptyShelfPainter.new),

  /// A Work with no Notes yet: an open book, both pages blank.
  blankPage(_BlankPagePainter.new);

  EmptyScene(this._painter);

  final _ScenePainter Function(Animation<double> light, {required bool rtl})
  _painter;
}

/// [scene], drawn up to [maxWidth] wide and centred. Its light comes on
/// once, gently, when the screen opens, or is simply on with reduced motion.
class EmptySceneView extends StatefulWidget {
  const EmptySceneView(this.scene, {this.maxWidth = 320, super.key});

  final EmptyScene scene;
  final double maxWidth;

  @override
  State<EmptySceneView> createState() => _EmptySceneViewState();
}

class _EmptySceneViewState extends State<EmptySceneView>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final _light = CurvedAnimation(
    parent: _controller,
    // A beat in the dark first, then the lamp warms up.
    curve: const Interval(0.25, 1, curve: Curves.easeOutCubic),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: _width / _height,
          child: CustomPaint(
            painter: widget.scene._painter(
              _light,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    ),
  );
}

// Every scene is drawn left to right in these units, then scaled to fit and
// flipped for right-to-left.
const _width = 240.0;
const _height = 120.0;

abstract class _ScenePainter extends CustomPainter {
  _ScenePainter(this.light, {required this.rtl}) : super(repaint: light);

  final Animation<double> light;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _width, size.height / _height);
    canvas.save();
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas
      ..translate(
        (size.width - _width * s) / 2,
        (size.height - _height * s) / 2,
      )
      ..scale(s)
      ..clipRect(const Rect.fromLTWH(0, 0, _width, _height));
    draw(canvas, light.value);
    canvas.restore();
  }

  /// Draws the scene in its own units, with the light [on] from 0 to 1.
  void draw(Canvas canvas, double on);

  @override
  bool shouldRepaint(_ScenePainter old) => old.rtl != rtl;
}

Paint _fill(Color color) => Paint()..color = color;

/// A warm pool of light around [center], strongest in the middle.
Paint _glow(Offset center, double radius, double alpha) => Paint()
  ..shader = RadialGradient(
    colors: [
      Palette.lamp.withValues(alpha: alpha),
      Palette.lamp.withValues(alpha: 0),
    ],
  ).createShader(Rect.fromCircle(center: center, radius: radius));

class _DarkWindowPainter extends _ScenePainter {
  _DarkWindowPainter(super.light, {required super.rtl});

  // The user's Window, second row from the top, in the middle of the block.
  static const _mine = (0, 2);

  @override
  void draw(Canvas canvas, double on) {
    // A few stars, the moon on the end side, and two dark neighbours.
    final star = _fill(Palette.mute.withValues(alpha: 0.45));
    for (final (x, y, r) in [(20.0, 18.0, 0.9), (52.0, 8.0, 0.7)]) {
      canvas.drawCircle(Offset(x, y), r, star);
    }
    for (final (x, y, r) in [(160.0, 10.0, 0.7), (196.0, 40.0, 0.8)]) {
      canvas.drawCircle(Offset(x, y), r, star);
    }
    canvas
      ..drawCircle(
        const Offset(214, 20),
        9,
        _fill(Palette.paper.withValues(alpha: 0.9)),
      )
      // The shadow side of the moon, so it reads as a crescent.
      ..drawCircle(const Offset(218, 17), 8, _fill(Palette.night))
      ..drawPath(
        Path()
          ..moveTo(0, _height)
          ..lineTo(0, 70)
          ..lineTo(18, 70)
          ..lineTo(18, 58)
          ..lineTo(28, 58)
          ..lineTo(28, _height)
          ..close(),
        _fill(Palette.deep),
      )
      ..drawRect(
        const Rect.fromLTWH(210, 64, 30, _height - 64),
        _fill(Palette.deep),
      )
      // The House: wall, chimney, the roof ledge.
      ..drawRect(const Rect.fromLTWH(78, 22, 12, 12), _fill(Palette.wall))
      ..drawRect(const Rect.fromLTWH(38, 30, 164, 90), _fill(Palette.wall))
      ..drawRect(const Rect.fromLTWH(34, 28, 172, 5), _fill(Palette.newFloor));

    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 5; c++) {
        final pane = Rect.fromLTWH(52.0 + c * 29, 44.0 + r * 36, 18, 22);
        _pane(canvas, pane, mine: (r, c) == _mine, on: on);
      }
    }
  }

  void _pane(
    Canvas canvas,
    Rect pane, {
    required bool mine,
    required double on,
  }) {
    final rounded = RRect.fromRectAndRadius(pane, const Radius.circular(1.5));
    canvas
      ..drawRRect(rounded, _fill(Palette.unlit))
      // A sill under each, catching a little moonlight.
      ..drawRect(
        Rect.fromLTWH(pane.left - 2, pane.bottom + 1, pane.width + 4, 2),
        _fill(Palette.raise),
      );
    if (!mine) {
      // The frame's middle bar.
      canvas.drawRect(
        Rect.fromLTWH(pane.center.dx - 0.5, pane.top, 1, pane.height),
        _fill(Palette.wall),
      );
      return;
    }
    // Yours: the lamp is in there, switched off, and the frame is warm,
    // as if it knows what's coming.
    final ink = _fill(Palette.indicator);
    final x = pane.left;
    final y = pane.top;
    canvas
      ..drawRRect(rounded.inflate(3), _glow(pane.center, 18, 0.24 * on))
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
          ..color = Palette.lamp.withValues(alpha: 0.65 * on),
      );
  }
}

class _EmptyShelfPainter extends _ScenePainter {
  _EmptyShelfPainter(super.light, {required super.rtl});

  @override
  void draw(Canvas canvas, double on) {
    const shade = Offset(120, 34);
    const shelfTop = 88.0;

    // The lamp's light on the wall and down onto the shelf.
    canvas
      ..drawCircle(
        const Offset(120, 66),
        54,
        _glow(const Offset(120, 66), 54, 0.14 * on),
      )
      ..drawPath(
        Path()
          ..moveTo(shade.dx - 13, shade.dy)
          ..lineTo(shade.dx + 13, shade.dy)
          ..lineTo(186, shelfTop)
          ..lineTo(54, shelfTop)
          ..close(),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.lamp.withValues(alpha: 0.22 * on),
              Palette.lamp.withValues(alpha: 0.04 * on),
            ],
          ).createShader(const Rect.fromLTRB(54, 34, 186, shelfTop)),
      )
      // The lamp: cord from the ceiling, the shade, the bulb under it.
      ..drawLine(
        const Offset(120, 0),
        const Offset(120, 20),
        Paint()
          ..color = Palette.mute.withValues(alpha: 0.6)
          ..strokeWidth = 1.2,
      )
      ..drawRRect(
        RRect.fromLTRBR(116.5, 18, 123.5, 22, const Radius.circular(1)),
        _fill(Palette.indicator),
      )
      ..drawOval(
        Rect.fromCenter(center: shade.translate(0, -1), width: 26, height: 6),
        _fill(Color.lerp(Palette.unlit, Palette.me, on)!),
      )
      ..drawPath(
        Path()
          ..moveTo(114, 21)
          ..lineTo(126, 21)
          ..quadraticBezierTo(131, 26, 133, shade.dy)
          ..lineTo(107, shade.dy)
          ..quadraticBezierTo(109, 26, 114, 21)
          ..close(),
        _fill(Palette.raise),
      )
      ..drawRect(
        const Rect.fromLTWH(107, 33, 26, 1.2),
        _fill(Palette.lamp.withValues(alpha: 0.5 * on)),
      );

    // The shelf: a plank on two brackets, its top catching the light.
    final plank = Color.lerp(Palette.raise, Palette.tickPassed, 0.55 * on)!;
    final bracket = _fill(Palette.line);
    for (final x in [62.0, 170.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, shelfTop + 6)
          ..lineTo(x + 8, shelfTop + 6)
          ..lineTo(x + 8, shelfTop + 7)
          ..lineTo(x + 1.5, shelfTop + 20)
          ..lineTo(x, shelfTop + 20)
          ..close(),
        bracket,
      );
    }
    canvas
      ..drawRect(
        const Rect.fromLTWH(46, shelfTop + 2, 148, 5),
        _fill(Palette.raise),
      )
      ..drawRect(const Rect.fromLTWH(46, shelfTop, 148, 2.5), _fill(plank));

    // A pot plant at the start and a bookend at the end, holding up nothing.
    final pot = _fill(Color.lerp(Palette.indicator, Palette.soft, 0.25 * on)!);
    final leaf = _fill(
      Color.lerp(const Color(0xFF2F4A44), const Color(0xFF5C8A6E), on)!,
    );
    canvas
      ..drawPath(
        Path()
          ..moveTo(60, 74)
          ..quadraticBezierTo(56, 63, 52, 58)
          ..quadraticBezierTo(60, 62, 62, 74)
          ..close(),
        leaf,
      )
      ..drawPath(
        Path()
          ..moveTo(63, 74)
          ..quadraticBezierTo(64, 60, 70, 54)
          ..quadraticBezierTo(70, 66, 65, 74)
          ..close(),
        leaf,
      )
      ..drawPath(
        Path()
          ..moveTo(66, 75)
          ..quadraticBezierTo(74, 66, 80, 64)
          ..quadraticBezierTo(76, 72, 67, 76)
          ..close(),
        leaf,
      )
      ..drawPath(
        Path()
          ..moveTo(55, 74)
          ..lineTo(73, 74)
          ..lineTo(71, shelfTop)
          ..lineTo(57, shelfTop)
          ..close(),
        pot,
      )
      ..drawRect(const Rect.fromLTWH(54, 73, 20, 3), pot)
      ..drawPath(
        Path()
          ..moveTo(170, shelfTop)
          ..lineTo(170, 66)
          ..quadraticBezierTo(170, 64, 172, 64)
          ..lineTo(174, 64)
          ..lineTo(174, shelfTop - 2)
          ..lineTo(186, shelfTop - 2)
          ..lineTo(186, shelfTop)
          ..close(),
        _fill(Color.lerp(Palette.indicator, Palette.mute, 0.4 * on)!),
      );
  }
}

class _BlankPagePainter extends _ScenePainter {
  _BlankPagePainter(super.light, {required super.rtl});

  @override
  void draw(Canvas canvas, double on) {
    const gutter = 120.0;
    canvas
      ..drawCircle(
        const Offset(gutter, 60),
        58,
        _glow(const Offset(gutter, 60), 58, 0.14 * on),
      )
      // The cover peeking out under the pages, then the block of pages.
      ..drawRRect(
        RRect.fromLTRBR(36, 22, 204, 102, const Radius.circular(3)),
        _fill(Palette.raise),
      )
      ..drawPath(
        _spread(gutter, top: 22, bottom: 99),
        _fill(Palette.soft.withValues(alpha: 0.55)),
      );

    final paper = Color.lerp(Palette.soft, Palette.paper, on)!;
    for (final side in [-1.0, 1.0]) {
      final page = _page(gutter, side, top: 18, bottom: 96);
      canvas
        ..drawPath(page, _fill(paper))
        // The page dips into the gutter's shadow.
        ..drawPath(
          page,
          Paint()
            ..shader =
                LinearGradient(
                  begin: side < 0
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: side < 0 ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [
                    Palette.deep.withValues(alpha: 0.28),
                    Palette.deep.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.22],
                ).createShader(
                  side < 0
                      ? const Rect.fromLTRB(44, 0, gutter, 1)
                      : const Rect.fromLTRB(gutter, 0, 196, 1),
                ),
        );
    }

    // A ribbon left hanging from the gutter.
    canvas.drawPath(
      Path()
        ..moveTo(gutter + 1, 92)
        ..lineTo(gutter + 6, 92)
        ..lineTo(gutter + 8, 112)
        ..lineTo(gutter + 5.5, 109)
        ..lineTo(gutter + 3, 113)
        ..close(),
      _fill(Color.lerp(Palette.tickPassed, Palette.lamp, on)!),
    );

    // The pencil, waiting on the end page.
    final wood = _fill(Color.lerp(Palette.soft, const Color(0xFFE8C9A0), on)!);
    canvas
      ..save()
      ..translate(176, 82)
      ..rotate(-0.42)
      ..drawRRect(
        RRect.fromLTRBR(-2, -2.6, 50, 2.6, const Radius.circular(1)),
        _fill(Palette.deep.withValues(alpha: 0.18)),
      )
      ..drawRect(
        const Rect.fromLTRB(0, -3, 40, 3),
        _fill(Color.lerp(Palette.tickPassed, Palette.lamp, on)!),
      )
      ..drawRect(
        const Rect.fromLTRB(0, -0.6, 40, 0.6),
        _fill(Palette.deep.withValues(alpha: 0.12)),
      )
      ..drawRect(const Rect.fromLTRB(40, -3, 44, 3), _fill(Palette.mute))
      ..drawRRect(
        RRect.fromLTRBR(44, -3, 49, 3, const Radius.circular(1.5)),
        _fill(const Color(0xFFD9918A)),
      )
      ..drawPath(
        Path()
          ..moveTo(0, -3)
          ..lineTo(-9, 0)
          ..lineTo(0, 3)
          ..close(),
        wood,
      )
      ..drawPath(
        Path()
          ..moveTo(-6, -1)
          ..lineTo(-9, 0)
          ..lineTo(-6, 1)
          ..close(),
        _fill(Palette.deep),
      )
      ..restore();
  }

  /// One page of the open book, curving up from the gutter to its outer
  /// edge: [side] is -1 for the start page and 1 for the end one.
  Path _page(
    double gutter,
    double side, {
    required double top,
    required double bottom,
  }) {
    final outer = gutter + side * 76;
    return Path()
      ..moveTo(gutter, top + 6)
      ..quadraticBezierTo(gutter + side * 30, top - 4, outer, top)
      ..lineTo(outer, bottom - 4)
      ..quadraticBezierTo(gutter + side * 30, bottom - 8, gutter, bottom)
      ..close();
  }

  /// Both pages at once, a little lower: the edges of the rest of the book.
  Path _spread(double gutter, {required double top, required double bottom}) =>
      Path()
        ..addPath(_page(gutter, -1, top: top, bottom: bottom), Offset.zero)
        ..addPath(_page(gutter, 1, top: top, bottom: bottom), Offset.zero);
}
