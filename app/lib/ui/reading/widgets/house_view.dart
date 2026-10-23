import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The House at night: an apartment block between two neighbours, with the
/// moon on the end side, so both swap sides in Persian. Only [windows] are
/// lit, each from the journal, and the user's own one pulses slowly. A line
/// under it says whose lights they are, or kindly that it's still empty.
class HouseView extends StatefulWidget {
  const HouseView({required this.windows, super.key});

  /// From [houseWindows]; more than the House has room for are left dark.
  final List<HouseWindow> windows;

  @override
  State<HouseView> createState() => _HouseViewState();
}

class _HouseViewState extends State<HouseView> with TickerProviderStateMixin {
  // The Windows come on one after another, once, when the screen opens.
  late final _light = AnimationController(
    vsync: this,
    duration: _lightUp(math.min(widget.windows.length, _slots.length)),
  );
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _light.value = 1;
      _pulse
        ..stop()
        ..value = 0;
    } else {
      if (_light.isDismissed) _light.forward();
      if (!_pulse.isAnimating) _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = widget.windows.length <= 1;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ExcludeSemantics(
              child: AspectRatio(
                aspectRatio: _width / _height,
                child: CustomPaint(
                  painter: _HousePainter(
                    windows: widget.windows.take(_slots.length).toList(),
                    light: _light,
                    pulse: _pulse,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            empty ? l10n.houseEmpty : l10n.houseYours,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Palette.mute,
              // Persian needs taller lines once the line wraps.
              height: Localizations.localeOf(context).languageCode == 'fa'
                  ? 1.7
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// The scene is drawn left to right in these units, then scaled to fit and
// flipped for right-to-left.
const _width = 312.0;
const _height = 128.0;

/// Where each Window goes, in the order [houseWindows] lists them: the
/// user's own in the middle, the rest spread over the block. Row, column.
const _slots = [
  (1, 3), (0, 1), (2, 5), (0, 5), (1, 0), (2, 2), (1, 6), //
  (0, 3), (2, 0), (1, 4), (0, 6), (2, 4), (1, 1), (0, 0), //
  (2, 6), (1, 5), (0, 2), (2, 1), (1, 2), (0, 4), (2, 3),
];
const _columns = 7;
const _rows = 3;

// Each lit Window fades in over half a second, a little after the one
// before, as in the mockups.
const _firstOn = 0.3;
const _between = 0.18;
const _fade = 0.5;
Duration _lightUp(int lit) => Duration(
  milliseconds: ((_firstOn + (lit - 1) * _between + _fade) * 1000).round(),
);

/// Earlier tonight: a dark pane with an amber outline (design section 8).
const _earlierFill = Color(0xFF2A3350);
const _earlierOutline = Color(0xFFE2B65A);

/// A past evening: a lamp turned low, never as bright as someone reading now.
final Color _pastFill = Color.lerp(Palette.unlit, Palette.lamp, 0.22)!;
const _meOutline = Color(0xFFFFF6DD);

class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.windows,
    required this.light,
    required this.pulse,
    required this.rtl,
  }) : super(repaint: Listenable.merge([light, pulse]));

  final List<HouseWindow> windows;
  final AnimationController light;
  final AnimationController pulse;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    // Short on room, the scene shrinks and stays centred.
    final s = math.min(size.width / _width, size.height / _height);
    canvas.save();
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    // The moon, then the neighbours, then the House itself.
    final deep = Paint()..color = Palette.deep;
    canvas
      ..translate((size.width - _width * s) / 2, size.height - _height * s)
      ..scale(s)
      ..drawCircle(
        const Offset(292, 16),
        11,
        Paint()..color = Palette.paper.withValues(alpha: 0.9),
      )
      ..drawPath(
        Path()
          ..moveTo(0, _height)
          ..lineTo(0, 84)
          ..lineTo(22, 84)
          ..lineTo(22, 70)
          ..lineTo(32, 70)
          ..lineTo(32, _height)
          ..close(),
        deep,
      )
      ..drawPath(
        Path()
          ..moveTo(276, _height)
          ..lineTo(276, 60)
          ..lineTo(292, 60)
          ..lineTo(292, 46)
          ..lineTo(_width, 46)
          ..lineTo(_width, _height)
          ..close(),
        deep,
      )
      ..drawPath(
        Path()
          ..moveTo(44, _height)
          ..lineTo(44, 30)
          ..lineTo(100, 30)
          ..lineTo(100, 16)
          ..lineTo(116, 16)
          ..lineTo(116, 30)
          ..lineTo(264, 30)
          ..lineTo(264, _height)
          ..close(),
        Paint()..color = Palette.wall,
      )
      ..drawRect(
        const Rect.fromLTWH(40, 28, 228, 5),
        Paint()..color = Palette.newFloor,
      );

    final lit = {for (final (i, w) in windows.indexed) _slots[i]: w};
    var order = 0;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _columns; c++) {
        final pane = Rect.fromLTWH(61.0 + c * 28, 44.0 + r * 28, 16, 18);
        final rounded = RRect.fromRectAndRadius(
          pane,
          const Radius.circular(1.5),
        );
        canvas.drawRRect(rounded, Paint()..color = Palette.unlit);
        final kind = lit[(r, c)];
        if (kind == null) continue;
        _window(canvas, rounded, kind, _on(order++));
      }
    }
    canvas.restore();
  }

  /// How far the [i]th lit Window has come on, from 0 to 1.
  double _on(int i) {
    if (light.isCompleted) return 1;
    final t = light.value * light.duration!.inMilliseconds / 1000;
    return ((t - _firstOn - i * _between) / _fade).clamp(0, 1);
  }

  void _window(Canvas canvas, RRect pane, HouseWindow kind, double on) {
    if (on == 0) return;
    switch (kind) {
      case HouseWindow.yours:
        // Down to 72% and back every 3.2 seconds.
        final breath =
            1 - 0.28 * (0.5 - 0.5 * math.cos(2 * math.pi * pulse.value));
        final a = on * breath;
        canvas
          ..drawRect(
            pane.outerRect.inflate(5),
            Paint()
              ..color = Palette.lamp.withValues(alpha: 0.18 * a)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          )
          ..drawRRect(pane, Paint()..color = Palette.me.withValues(alpha: a))
          ..drawRRect(
            pane,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = _meOutline.withValues(alpha: a),
          );
      case HouseWindow.earlierTonight:
        canvas
          ..drawRRect(pane, Paint()..color = _earlierFill.withValues(alpha: on))
          ..drawRRect(
            pane,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = _earlierOutline.withValues(alpha: 0.6 * on),
          );
      case HouseWindow.pastEvening:
        canvas.drawRRect(
          pane,
          Paint()..color = _pastFill.withValues(alpha: on),
        );
    }
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.rtl != rtl || !listEquals(old.windows, windows);
}
