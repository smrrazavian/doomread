import 'package:flutter/material.dart';

/// A number rolling like an odometer from [from] to [to]: each character
/// that changes turns over, upwards when [up], while the rest stay put.
/// When the length changes, the whole number turns at once.
///
/// It draws the number centred in its box exactly as a centred text field
/// of the same width would, so it can stand in for the field's own text.
/// Digits run left to right, in Persian too.
class Odometer extends StatelessWidget {
  const Odometer({
    required this.from,
    required this.to,
    required this.up,
    required this.t,
    required this.style,
    super.key,
  });

  final String from;
  final String to;
  final bool up;

  /// How far through the roll, from 0 to 1.
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _OdometerPainter(
      from: from,
      to: to,
      up: up,
      t: t,
      style: style,
      scaler: MediaQuery.textScalerOf(context),
    ),
  );
}

class _OdometerPainter extends CustomPainter {
  _OdometerPainter({
    required this.from,
    required this.to,
    required this.up,
    required this.t,
    required this.style,
    required this.scaler,
  });

  final String from;
  final String to;
  final bool up;
  final double t;
  final TextStyle style;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter lay(String text) => TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(minWidth: size.width, maxWidth: size.width);
    final (old, next) = (lay(from), lay(to));
    final turn = (up ? 1 : -1) * size.height;
    final (out, inn) = (Offset(0, -t * turn), Offset(0, (1 - t) * turn));

    /// [p] shifted by [dy], seen only through the [i]th character's column.
    void column(TextPainter p, int i, Offset dy) {
      for (final box in p.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      )) {
        canvas
          ..save()
          ..clipRect(Rect.fromLTRB(box.left, 0, box.right, size.height));
        p.paint(canvas, dy);
        canvas.restore();
      }
    }

    canvas
      ..save()
      ..clipRect(Offset.zero & size);
    if (from.length != to.length) {
      old.paint(canvas, out);
      next.paint(canvas, inn);
    } else {
      for (var i = 0; i < to.length; i++) {
        if (from[i] == to[i]) {
          column(next, i, Offset.zero);
        } else {
          column(old, i, out);
          column(next, i, inn);
        }
      }
    }
    canvas.restore();
    old.dispose();
    next.dispose();
  }

  @override
  bool shouldRepaint(_OdometerPainter old) =>
      old.t != t ||
      old.from != from ||
      old.to != to ||
      old.up != up ||
      old.style != style ||
      old.scaler != scaler;
}
