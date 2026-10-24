import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

/// One Note, read by the light of the user's own Window: the lit Window at
/// the top throws its lamplight down across a sheet of paper with the Note
/// on it, and the Work's «title» under it. No numbers: it's the user's own
/// sentence, and only the one Note they chose to share.
///
/// The Note keeps its own script's direction, so an English Note on a
/// Persian card still reads left to right. The Window and its light mirror
/// with the layout.
class NotePoster extends StatelessWidget {
  const NotePoster({required this.note, required this.work, super.key});

  final String note;
  final Work work;

  @override
  Widget build(BuildContext context) {
    final type = PosterType(fa: isPersian(context));
    final note = this.note.trim();
    final rtl = Bidi.detectRtlDirectionality(note);
    // A short Note is set large; a long one steps down so it still fits.
    final size = switch (note.length) {
      <= 70 => 25.0,
      <= 140 => 21.0,
      _ => 18.0,
    };

    return PosterFrame(
      sky: const PosterSky(stars: 36, starDepth: 0.35),
      // The Window and the paper it lights, as one group in the middle.
      child: Center(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _Beam(Directionality.of(context))),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _Window(),
                ),
                // Room for the light to fall before it reaches the paper.
                const SizedBox(height: 64),
                Tilt(
                  degrees: 2,
                  child: _Sheet(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          note,
                          style: type
                              .book(size, Palette.night)
                              .copyWith(height: rtl ? 1.9 : 1.45),
                          textDirection: rtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          maxLines: 9,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 24),
                        WorkByline(
                          work: work,
                          title: type
                              .book(15, Palette.night, FontWeight.w600)
                              .copyWith(height: type.fa ? 1.7 : 1.3),
                          author: type.ui(12, Palette.inkFaded),
                          align: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The Window's size, above the paper it lights.

const _windowSize = Size(58, 74);

/// The user's own Window, lit, in its frame on the wall of the night.
class _Window extends StatelessWidget {
  const _Window();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsetsDirectional.only(end: 10),
    width: _windowSize.width,
    height: _windowSize.height,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Palette.raise,
      borderRadius: BorderRadius.circular(3),
      boxShadow: [
        BoxShadow(
          color: Palette.lamp.withValues(alpha: 0.55),
          blurRadius: 30,
          spreadRadius: 2,
        ),
      ],
    ),
    child: const CustomPaint(painter: _Glass()),
  );
}

/// The lit glass with its cross of glazing bars.
class _Glass extends CustomPainter {
  const _Glass();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.3),
          radius: 0.9,
          colors: [Palette.me, Palette.lamp],
        ).createShader(rect),
    );
    final bar = Paint()
      ..color = Palette.raise
      ..strokeWidth = 3;
    canvas
      ..drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        bar,
      )
      ..drawLine(
        Offset(0, size.height * 0.42),
        Offset(size.width, size.height * 0.42),
        bar,
      );
  }

  @override
  bool shouldRepaint(_Glass oldDelegate) => false;
}

/// The Window's light falling down across the card and onto the paper:
/// widening from the sill, fading as it goes.
class _Beam extends CustomPainter {
  const _Beam(this.direction);

  /// The Window is at the end: the right, or the left in Persian.
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    double x(double fromEnd) =>
        direction == TextDirection.ltr ? size.width - fromEnd : fromEnd;
    const sill = 66.0;
    final floor = size.height - 30;
    final path = Path()
      ..moveTo(x(14 + _windowSize.width), sill)
      ..lineTo(x(6), sill)
      ..lineTo(x(-40), floor)
      ..lineTo(x(size.width), floor)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Palette.lamp.withValues(alpha: 0.22),
            Palette.lamp.withValues(alpha: 0.07),
            Palette.lamp.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromLTRB(0, sill, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_Beam old) => old.direction != direction;
}

/// A sheet of paper, warmer where the lamplight lands on it.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const PaperShadow(),
    child: Container(
      width: 296,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const RadialGradient(
          center: AlignmentDirectional.topEnd,
          radius: 1.3,
          colors: [_lamplit, Palette.paper],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: child,
    ),
  );

  /// Paper where the Window's light falls on it.
  static const _lamplit = Color(0xFFFAE8BC);
}
