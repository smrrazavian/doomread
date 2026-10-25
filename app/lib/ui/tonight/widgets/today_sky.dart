import 'dart:math' as math;

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/tonight/view_models/today_sky_view_model.dart';
import 'package:doomread/ui/tonight/view_models/tonight_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

/// The hour of [t] on Today's clock, from 4 to 28: the small hours count on
/// from the evening before, as [eveningOf] does, so the sky never runs
/// backwards through the night.
double skyHour(DateTime t) => (t.hour + t.minute / 60 - 4) % 24 + 4;

enum DayPart { morning, afternoon, evening, night }

/// The part of the day at [hour] (see [skyHour]), for the greeting.
DayPart partOfDay(double hour) => switch (hour) {
  < 12 => DayPart.morning,
  < 17 => DayPart.afternoon,
  < 20 => DayPart.evening,
  _ => DayPart.night,
};

/// How many neighbours' windows there are in the skyline.
const skyWindows = 8;

/// How many of them are lit at [hour]: none before five, then one by one
/// until all of them by eight.
int litWindows(double hour) =>
    ((hour - 17) / 3 * skyWindows).clamp(0, skyWindows).ceil();

/// The header over Today: the sky at this time of day over a small skyline,
/// the greeting, and what's left today.
class TodaySky extends StatelessWidget {
  const TodaySky({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => TodaySkyViewModel(
      c.read<WorkRepository>(),
      c.read<SessionRepository>(),
    ),
    child: const _Sky(),
  );
}

class _Sky extends StatelessWidget {
  const _Sky();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<TodaySkyViewModel>();
    // The current Work's kind, from Today's own view model.
    final (workLoaded, kind) = context
        .select<TonightViewModel, (bool, String?)>(
          (t) => (t.loaded, t.road?.work.kind.name),
        );
    final lang = Localizations.localeOf(context).languageCode;
    final hour = skyHour(vm.now);
    final greeting = l10n.todayGreeting(
      DateFormat.EEEE(lang).format(eveningOf(vm.now)),
      partOfDay(hour).name,
    );
    // Said only once both are known, never "nothing planned" by mistake.
    final sub = !vm.loaded || !workLoaded
        ? null
        : switch ((vm.undone, kind)) {
            (0, null) => l10n.todaySkyFree,
            (0, final kind?) => l10n.todaySkyOnlyWork(kind),
            (final n, null) => l10n.todaySkyTasks(n),
            (final n, final kind?) => l10n.todaySkyBoth(
              l10n.todaySkyTasks(n),
              l10n.todaySkyThen(kind),
            ),
          };
    // Paper on a bright noon sky still needs to read.
    const shadows = [Shadow(color: Color(0x80141B2F), blurRadius: 8)];
    // Under the status bar too, with the greeting below it and level with
    // the bar's actions.
    final top = MediaQuery.viewPaddingOf(context).top;
    return SizedBox(
      height: top + 116,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Back from the background, the sky moves on to the time it is,
          // lighting windows as it goes; with reduced motion it's just there.
          // A new evening starts its own sky rather than run this one back.
          TweenAnimationBuilder<double>(
            key: ValueKey(eveningOf(vm.now)),
            tween: Tween(end: hour),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, h, _) => CustomPaint(
              painter: _SkyPainter(
                hour: h,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
          PositionedDirectional(
            start: 24,
            end: 64,
            top: top + 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: text.headlineSmall?.copyWith(shadows: shadows),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: text.bodyMedium?.copyWith(
                      color: Palette.paper,
                      shadows: shadows,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The sky's colours, top and bottom, through the day: warm morning, blue
/// midday, dusk at six, then night.
const List<(double, Color, Color)> _stops = [
  (5.5, Palette.deep, Palette.night),
  (7.0, Color(0xFF3A4C7A), Color(0xFFE9A86B)),
  (12.0, Color(0xFF4A6AA6), Color(0xFF9DB7DE)),
  (17.0, Color(0xFF4A3D6E), Color(0xFFE58F65)),
  (19.0, Color(0xFF2A2F55), Color(0xFF7B5A86)),
  (21.0, Palette.night, Color(0xFF1E2848)),
  (23.5, Palette.deep, Palette.night),
];

(Color, Color) _skyAt(double hour) {
  if (hour <= _stops.first.$1) return (_stops.first.$2, _stops.first.$3);
  for (final (i, (b, top, bottom)) in _stops.indexed.skip(1)) {
    if (hour <= b) {
      final (a, top0, bottom0) = _stops[i - 1];
      final t = (hour - a) / (b - a);
      return (Color.lerp(top0, top, t)!, Color.lerp(bottom0, bottom, t)!);
    }
  }
  return (_stops.last.$2, _stops.last.$3);
}

/// The skyline's blocks and windows, in a 340 by 150 sky.
const List<(Rect, Color)> _blocks = [
  (Rect.fromLTWH(0, 116, 44, 34), Palette.deep),
  (Rect.fromLTWH(48, 102, 60, 48), Palette.wall),
  (Rect.fromLTWH(112, 122, 40, 28), Palette.deep),
  (Rect.fromLTWH(230, 108, 70, 42), Palette.wall),
  (Rect.fromLTWH(304, 124, 36, 26), Palette.deep),
];
const _windows = [
  Offset(56, 110), Offset(72, 124), Offset(90, 112), Offset(240, 116), //
  Offset(258, 128), Offset(276, 116), Offset(286, 134), Offset(120, 130),
];

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.hour, required this.rtl});

  final double hour;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final (top, bottom) = _skyAt(hour);
    canvas
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(Offset.zero & size),
      )
      ..save();
    if (rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final sx = size.width / 340;
    final sy = size.height / 150;
    _paintSunOrMoon(canvas, sx, sy);
    for (final (r, colour) in _blocks) {
      canvas.drawRect(
        Rect.fromLTRB(r.left * sx, r.top * sy, r.right * sx, size.height),
        Paint()..color = colour,
      );
    }
    final lit = litWindows(hour);
    for (final (i, w) in _windows.indexed) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w.dx * sx, w.dy * sy, 7 * sx, 8 * sy),
          Radius.circular(sx),
        ),
        Paint()..color = Palette.lamp.withValues(alpha: i < lit ? 0.85 : 0.08),
      );
    }
    canvas.restore();
  }

  /// The sun on its arc from seven to half past seven, then the moon. Both
  /// keep to the rooftops at the end, under the bar's actions and clear of
  /// the greeting.
  void _paintSunOrMoon(Canvas canvas, double sx, double sy) {
    final night = hour >= 19.5 || hour < 5.5;
    final p =
        (night ? (hour < 5.5 ? 1.0 : (hour - 19.5) / 4) : (hour - 7) / 12.5)
            .clamp(0.0, 1.0);
    final r = 17 * sy;
    final c = Offset(
      (250 + p * 70) * sx,
      (125 - math.sin(math.pi * p) * 37) * sy,
    );
    if (night) {
      final disc = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      final shade = Path()
        ..addOval(
          Rect.fromCircle(center: c - Offset(9 * sy, 4 * sy), radius: r),
        );
      canvas.drawPath(
        Path.combine(PathOperation.difference, disc, shade),
        Paint()..color = Palette.paper,
      );
      return;
    }
    canvas
      ..drawCircle(
        c,
        r + 6 * sy,
        Paint()
          ..color = const Color(0x73FFD678)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * sy),
      )
      ..drawCircle(
        c,
        r,
        Paint()..color = hour > 16.5 ? const Color(0xFFF3A96A) : Palette.me,
      );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.hour != hour || old.rtl != rtl;
}
