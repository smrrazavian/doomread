import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// One step of a number in a field: what it showed, what it shows now, and
/// whether it went up. Each step is its own Roll, even to the same number.
class Roll {
  Roll({required this.from, required this.to, required this.up});

  final String from;
  final String to;
  final bool up;
}

/// How long a number takes to roll over.
const _rollTime = Duration(milliseconds: 260);

/// A centred text field whose number rolls over like an odometer each time
/// [roll] is a new step. While it rolls, the field's own text is hidden and
/// the roll is drawn exactly where the field draws its text. With reduced
/// motion the number simply changes.
class RollingField extends StatefulWidget {
  const RollingField({
    required this.roll,
    required this.style,
    required this.builder,
    super.key,
  });

  /// The latest step, or null before the first.
  final Roll? roll;

  /// The style the field draws its text in.
  final TextStyle style;

  /// The field itself, `hidden` while the roll stands in for its text.
  final Widget Function(BuildContext context, {required bool hidden}) builder;

  @override
  State<RollingField> createState() => _RollingFieldState();
}

class _RollingFieldState extends State<RollingField>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: _rollTime)
    // The field shows its own text again once the roll is over.
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() {});
    });

  /// Where the roll is drawn, over the field's text.
  Rect? _textAt;

  @override
  void didUpdateWidget(RollingField old) {
    super.didUpdateWidget(old);
    final roll = widget.roll;
    if (roll == null || identical(roll, old.roll) || roll.from == roll.to) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) return;
    _textAt = _measure(roll.from);
    if (_textAt != null) _turn.forward(from: 0);
  }

  /// The field's text box as laid out with [shown], narrowed to be centred
  /// on the text: centred text keeps its middle whatever the number, but
  /// the field keeps room for the caret on one side, off the box's middle.
  Rect? _measure(String shown) {
    final box = context.findRenderObject() as RenderBox?;
    final text = box == null ? null : _editable(box);
    if (box == null || text == null) return null;
    final at = text.localToGlobal(Offset.zero, ancestor: box) & text.size;
    final glyphs = text
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: shown.length),
        )
        .map((b) => b.toRect())
        .fold<Rect?>(null, (all, r) => all?.expandToInclude(r) ?? r);
    final middle = glyphs == null ? at.center.dx : at.left + glyphs.center.dx;
    final half = math.min(middle - at.left, at.right - middle);
    return Rect.fromLTRB(middle - half, at.top, middle + half, at.bottom);
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rolling = _turn.isAnimating && _textAt != null;
    return Stack(
      children: [
        widget.builder(context, hidden: rolling),
        if (rolling)
          Positioned.fromRect(
            rect: _textAt!,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, _) => Odometer(
                  roll: widget.roll!,
                  t: Curves.easeOutCubic.transform(_turn.value),
                  style: widget.style,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The field's text, found in its render tree.
RenderEditable? _editable(RenderObject o) {
  if (o is RenderEditable) return o;
  RenderEditable? found;
  o.visitChildren((c) => found ??= _editable(c));
  return found;
}

/// A [roll] drawn [t] of the way through: each character that changes turns
/// over, upwards when it went up, while the rest stay put. When the length
/// changes, the whole number turns at once.
///
/// It draws the number centred in its box exactly as a centred text field
/// of the same width would. Digits run left to right, in Persian too.
class Odometer extends StatelessWidget {
  const Odometer({
    required this.roll,
    required this.t,
    required this.style,
    super.key,
  });

  final Roll roll;

  /// How far through the roll, from 0 to 1.
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _OdometerPainter(
      roll: roll,
      t: t,
      style: style,
      scaler: MediaQuery.textScalerOf(context),
    ),
  );
}

class _OdometerPainter extends CustomPainter {
  _OdometerPainter({
    required this.roll,
    required this.t,
    required this.style,
    required this.scaler,
  });

  final Roll roll;
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
    final Roll(:from, :to, :up) = roll;
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
      old.roll != roll ||
      old.style != style ||
      old.scaler != scaler;
}
