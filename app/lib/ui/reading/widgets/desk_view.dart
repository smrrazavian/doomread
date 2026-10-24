import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// A desk at night, the scene of a Task's Session where a book has the
/// House: a window on the night skyline, a desk lamp's warm beam, a laptop
/// with a softly glowing screen and a blinking caret, a mug, and the phone
/// face down. The lamp stands on the end side, so the scene mirrors in
/// Persian.
///
/// Nothing moves but the caret, and with reduced motion not even that.
class DeskView extends StatefulWidget {
  const DeskView({super.key});

  @override
  State<DeskView> createState() => _DeskViewState();
}

class _DeskViewState extends State<DeskView>
    with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1060),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _blink
        ..stop()
        ..value = 0;
    } else if (!_blink.isAnimating) {
      _blink.repeat();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: _width / _height,
        child: CustomPaint(
          painter: _DeskPainter(
            blink: _blink,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    ),
  );
}

// The scene is drawn on a 296 by 180 grid, scaled to fit.
const _width = 296.0;
const _height = 180.0;

// Night colours of the desk, beside the Palette's.
const _innerWall = Color(0xFF26315A);
const _skyline = Color(0xFF1A2140);
const _earlier = Color(0x99E2B65A);
const _laptop = Color(0xFF0F1530);
const _screen = Color(0xFF2F4A86);
const _screenText = Color(0xFFC9D7FF);
const _phone = Color(0xFF0B1024);
const _caret = Color(0xFFFFFFFF);

class _DeskPainter extends CustomPainter {
  _DeskPainter({required this.blink, required this.rtl})
    : super(repaint: blink);

  final Animation<double> blink;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.width / _width;
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    canvas.scale(scale);
    Paint fill(Color c) => Paint()..color = c;
    RRect box(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    canvas
      // The room, and the window on the night.
      ..drawRRect(box(0, 0, _width, _height, 14), fill(Palette.wall))
      ..drawRRect(box(20, 18, 256, 128, 6), fill(_innerWall))
      ..drawRRect(box(30, 26, 110, 80, 4), fill(Palette.deep))
      ..drawCircle(
        const Offset(116, 44),
        8,
        fill(Palette.paper.withValues(alpha: 0.85)),
      )
      ..drawRect(const Rect.fromLTWH(40, 64, 18, 42), fill(_skyline))
      ..drawRect(const Rect.fromLTWH(62, 54, 22, 52), fill(_skyline))
      ..drawRect(
        const Rect.fromLTWH(66, 60, 5, 6),
        fill(Palette.lamp.withValues(alpha: 0.7)),
      )
      ..drawRect(const Rect.fromLTWH(74, 72, 5, 6), fill(_earlier))
      // The lamp: its arm, its shade, and the warm beam on the desk.
      ..drawPath(
        Path()
          ..moveTo(206, 54)
          ..relativeLineTo(18, -22)
          ..relativeLineTo(10, 8),
        Paint()
          ..color = Palette.soft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(
        Path()
          ..moveTo(226, 28)
          ..relativeLineTo(20, 4)
          ..relativeLineTo(-8, 16)
          ..close(),
        fill(Palette.lamp),
      )
      ..drawPath(
        Path()
          ..moveTo(236, 44)
          ..lineTo(180, 146)
          ..lineTo(290, 146)
          ..close(),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.lamp.withValues(alpha: 0.35),
              Palette.lamp.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(180, 44, 110, 102)),
      )
      // The laptop, its screen glowing with a few lines of work.
      ..drawRRect(box(150, 96, 74, 46, 4), fill(_laptop))
      ..drawRRect(box(154, 100, 66, 38, 2), fill(_screen))
      ..drawRRect(
        box(160, 108, 40, 3, 1.5),
        fill(_screenText.withValues(alpha: 0.8)),
      )
      ..drawRRect(
        box(160, 115, 52, 3, 1.5),
        fill(_screenText.withValues(alpha: 0.55)),
      )
      ..drawRRect(
        box(160, 122, 30, 3, 1.5),
        fill(_screenText.withValues(alpha: 0.55)),
      )
      // The caret, on for the first half of each blink.
      ..drawRect(
        const Rect.fromLTWH(192, 121, 2, 6),
        fill(blink.value < 0.5 ? _caret : _caret.withValues(alpha: 0)),
      )
      ..drawRRect(box(140, 142, 94, 5, 2), fill(_laptop))
      // The mug.
      ..drawRRect(box(246, 124, 16, 18, 3), fill(Palette.paper))
      ..drawPath(
        Path()
          ..moveTo(262, 128)
          ..quadraticBezierTo(268, 128, 268, 133)
          ..quadraticBezierTo(268, 138, 262, 138),
        Paint()
          ..color = Palette.paper
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      // The phone, face down.
      ..drawRRect(box(40, 134, 40, 10, 3), fill(_phone))
      // The desk.
      ..drawRect(const Rect.fromLTWH(20, 146, 256, 6), fill(_skyline))
      ..restore();
  }

  @override
  bool shouldRepaint(_DeskPainter old) => old.rtl != rtl;
}
