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
///
/// When it opens, the user's Window switches on first, like a lamp, and the
/// rest follow. Back from an Urge let pass ([backOn]) the others are on
/// already and only the user's flickers back on.
class HouseView extends StatefulWidget {
  const HouseView({
    required this.windows,
    this.kind,
    this.backOn = false,
    super.key,
  });

  /// From [houseWindows]; more than the House has room for are left dark.
  final List<HouseWindow> windows;

  /// What the user is on, shown in their own Window: a lamp for a book, a
  /// TV for a film or series, headphones for a podcast. Plain when null.
  final WorkKind? kind;

  /// Whether the user is back from an Urge they let pass. Read once, when
  /// the House first shows.
  final bool backOn;

  @override
  State<HouseView> createState() => _HouseViewState();
}

class _HouseViewState extends State<HouseView> with TickerProviderStateMixin {
  // The Windows come on one after another, once, when the screen opens;
  // or only the user's flickers, when they're back from an Urge.
  late final _light = AnimationController(
    vsync: this,
    duration: widget.backOn
        ? _flickerTime
        : _lightUp(math.min(widget.windows.length, _slots.length)),
  );
  late final _backOn = widget.backOn;
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
                    backOn: _backOn,
                    kind: widget.kind,
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

/// The user's own Window doesn't fade in: it switches on like a lamp, with
/// a stutter before it holds. Brightness at points through its half second.
const _lamp = [(0.0, 0.0), (0.08, 1.0), (0.2, 0.4), (0.3, 1.0)];

/// Back from an Urge: a couple of flickers, then on.
const _flickerTime = Duration(milliseconds: 700);
const _flicker = [
  (0.0, 0.0),
  (0.1, 0.9),
  (0.22, 0.15),
  (0.36, 1.0),
  (0.48, 0.45),
  (0.62, 1.0),
];

/// [keys] at [t], straight between them and holding after the last.
double _at(List<(double, double)> keys, double t) {
  for (var k = 1; k < keys.length; k++) {
    final (t1, v1) = keys[k];
    if (t <= t1) {
      final (t0, v0) = keys[k - 1];
      return v0 + (v1 - v0) * ((t - t0) / (t1 - t0));
    }
  }
  return keys.last.$2;
}

/// Earlier tonight: a dark pane with an amber outline (design section 8).
const _earlierFill = Color(0xFF2A3350);
const _earlierOutline = Color(0xFFE2B65A);

/// A past evening: a lamp turned low, never as bright as someone reading now.
final Color _pastFill = Color.lerp(Palette.unlit, Palette.lamp, 0.22)!;
const _meOutline = Color(0xFFFFF6DD);

/// A film or series: the user's Window glows TV blue instead of lamplight.
const _tvGlow = Color(0xFFA9C4F5);
const _tvOutline = Color(0xFFE4EEFF);

/// The things in the user's Window, in shadow against its light.
final Color _shadow = Palette.deep.withValues(alpha: 0.8);

class _HousePainter extends CustomPainter {
  _HousePainter({
    required this.windows,
    required this.light,
    required this.pulse,
    required this.backOn,
    required this.kind,
    required this.rtl,
  }) : super(repaint: Listenable.merge([light, pulse]));

  final List<HouseWindow> windows;
  final AnimationController light;
  final AnimationController pulse;
  final bool backOn;
  final WorkKind? kind;
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
    // The user's own comes on first, the others in reading order after it.
    var order = 1;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _columns; c++) {
        final pane = Rect.fromLTWH(61.0 + c * 28, 44.0 + r * 28, 16, 18);
        final rounded = RRect.fromRectAndRadius(
          pane,
          const Radius.circular(1.5),
        );
        canvas.drawRRect(rounded, Paint()..color = Palette.unlit);
        final window = lit[(r, c)];
        if (window == null) continue;
        final yours = window == HouseWindow.yours;
        _window(canvas, rounded, window, _on(yours ? 0 : order++, yours));
      }
    }
    canvas.restore();
  }

  /// How far the [i]th lit Window has come on, from 0 to 1; the user's
  /// own when [yours].
  double _on(int i, bool yours) {
    if (light.isCompleted) return 1;
    if (backOn) return yours ? _at(_flicker, light.value) : 1;
    final t = light.value * light.duration!.inMilliseconds / 1000;
    final on = ((t - _firstOn - i * _between) / _fade).clamp(0.0, 1.0);
    return yours ? _at(_lamp, on) : on;
  }

  void _window(Canvas canvas, RRect pane, HouseWindow window, double on) {
    if (on == 0) return;
    switch (window) {
      case HouseWindow.yours:
        // Down to 72% and back every 3.2 seconds.
        final breath =
            1 - 0.28 * (0.5 - 0.5 * math.cos(2 * math.pi * pulse.value));
        final a = on * breath;
        final tv = kind == WorkKind.series || kind == WorkKind.film;
        canvas
          ..drawRect(
            pane.outerRect.inflate(5),
            Paint()
              ..color = (tv ? _tvGlow : Palette.lamp).withValues(
                alpha: 0.18 * a,
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          )
          ..drawRRect(
            pane,
            Paint()..color = (tv ? _tvGlow : Palette.me).withValues(alpha: a),
          );
        if (kind case final kind?) _silhouette(canvas, pane.outerRect, kind, a);
        canvas.drawRRect(
          pane,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = (tv ? _tvOutline : _meOutline).withValues(alpha: a),
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

  /// What the user is on, drawn small in their Window from the start side,
  /// so it mirrors with the scene in Persian.
  void _silhouette(Canvas canvas, Rect pane, WorkKind kind, double a) {
    final ink = Paint()..color = _shadow.withValues(alpha: _shadow.a * a);
    final x = pane.left;
    final y = pane.top;
    switch (kind) {
      case WorkKind.paperBook || WorkKind.ebook:
        // A reading lamp: shade, stem and foot, and its pool of light.
        canvas
          ..drawCircle(
            Offset(x + 6, y + 10),
            4,
            Paint()
              ..color = Palette.paper.withValues(alpha: 0.7 * a)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
          )
          ..drawPath(
            Path()
              ..moveTo(x + 4.5, y + 4)
              ..lineTo(x + 7.5, y + 4)
              ..lineTo(x + 9.5, y + 8.5)
              ..lineTo(x + 2.5, y + 8.5)
              ..close(),
            ink,
          )
          ..drawRect(Rect.fromLTWH(x + 5.5, y + 8.5, 1, 6), ink)
          ..drawRect(Rect.fromLTWH(x + 3.5, y + 14.5, 5, 1.5), ink);
      case WorkKind.series || WorkKind.film:
        // An old TV with rabbit ears, its screen a brighter blue.
        final ears = Paint()
          ..color = ink.color
          ..strokeWidth = 0.8
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(Offset(x + 6, y + 8), Offset(x + 4, y + 4), ears)
          ..drawLine(Offset(x + 6, y + 8), Offset(x + 9, y + 4.5), ears)
          ..drawRRect(
            RRect.fromLTRBR(
              x + 2,
              y + 8,
              x + 11,
              y + 15,
              const Radius.circular(1),
            ),
            ink,
          )
          ..drawRect(
            Rect.fromLTRB(x + 3.2, y + 9.2, x + 9.8, y + 13.8),
            Paint()..color = _tvOutline.withValues(alpha: a),
          )
          ..drawRect(Rect.fromLTWH(x + 3, y + 15, 1.2, 1.5), ink)
          ..drawRect(Rect.fromLTWH(x + 8.8, y + 15, 1.2, 1.5), ink);
      case WorkKind.podcast:
        // Headphones: the band over the top and a cup on each side.
        canvas
          ..drawArc(
            Rect.fromLTRB(x + 3.5, y + 4, x + 12.5, y + 13),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = ink.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          )
          ..drawRRect(
            RRect.fromLTRBR(
              x + 2.5,
              y + 8,
              x + 5.5,
              y + 13,
              const Radius.circular(1),
            ),
            ink,
          )
          ..drawRRect(
            RRect.fromLTRBR(
              x + 10.5,
              y + 8,
              x + 13.5,
              y + 13,
              const Radius.circular(1),
            ),
            ink,
          );
    }
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.rtl != rtl || old.kind != kind || !listEquals(old.windows, windows);
}
