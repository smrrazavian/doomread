import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// Tonight's Session as a thermal receipt, on paper under the lamp: the
/// Work, how long, what got let pass, the Planned breaks, and a sign-off in
/// the user's Tone. A Slip is printed as coming back, never as a minus.
///
/// It's laid out on the fixed [PosterCanvas]. Persian gets its own layout:
/// right to left, Persian digits, Naskh for the title.
class ReceiptPoster extends StatelessWidget {
  const ReceiptPoster({
    required this.work,
    required this.session,
    required this.signOff,
    this.pages,
    super.key,
  });

  final Work work;

  /// Tonight's Session, measured once it stopped.
  final Session session;

  /// The part of the Work it covered; null leaves the line out.
  final ({int from, int to})? pages;

  /// The Tone's line at the foot, from Voice.
  final String signOff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fa = isPersian(context);
    final type = PosterType(fa: fa);
    final ink = _Ink(type);
    final minutes = session.reading.inMinutes;
    final longest = session.longestStretch.inMinutes;
    final breaks = session.breaks.length;
    final slips = session.slips;
    final start = session.startedAt;
    final end = session.stretches.lastOrNull?.end;
    final pages = this.pages;

    return PosterCanvas(
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: PosterSky(stars: 60, starDepth: 0.9)),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: LampGlow(at: Offset(0.5, 0.42), reach: 300),
            ),
          ),
          PositionedDirectional(
            top: 26,
            start: 24,
            child: Wordmark(l10n.appTitle, type.mark),
          ),
          Positioned.fill(
            top: 56,
            child: Center(
              child: Transform.rotate(
                // A receipt dropped on the desk, never quite straight.
                angle: (fa ? 1 : -1) * 1.4 * math.pi / 180,
                child: _Paper(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: _LitWindow()),
                      const SizedBox(height: 6),
                      Text(
                        l10n.cardReceiptHeading,
                        style: ink.heading,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      if (start != null && end != null)
                        Text(
                          l10n.cardReceiptWhen(
                            formatDayMonth(context, eveningOf(start)),
                            formatTime(start, locale),
                            formatTime(end, locale),
                          ),
                          style: ink.small,
                          textAlign: TextAlign.center,
                        ),
                      const _Dashes(),
                      Text(
                        l10n.sharePosterTitle('\u2068${work.title}\u2069'),
                        style: ink.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (work.author.trim().isNotEmpty)
                        Text(
                          work.author,
                          style: ink.small,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const _Dashes(),
                      if (pages != null)
                        _Line(
                          ink: ink,
                          label: switch (work.kind.unit) {
                            WorkUnit.page => l10n.cardReceiptPages,
                            WorkUnit.episode => l10n.cardReceiptEpisodes,
                            WorkUnit.second => l10n.cardReceiptTime,
                          },
                          value: rangeOf(context, work, pages.from, pages.to),
                        ),
                      _Line(
                        ink: ink,
                        label: l10n.cardReceiptLongest,
                        value: l10n.minutesShort(longest),
                      ),
                      // A zero next to a Slip would read as a score.
                      if (session.urgesLetPass > 0)
                        _Line(
                          ink: ink,
                          label: l10n.cardReceiptUrges,
                          value: formatNumber(session.urgesLetPass, locale),
                        ),
                      if (breaks > 0)
                        _Line(
                          ink: ink,
                          icon: const _TeaGlass(),
                          label: l10n.cardReceiptBreaks,
                          value: formatNumber(breaks, locale),
                        ),
                      if (slips > 0) ...[
                        const SizedBox(height: 2),
                        Text(l10n.cardReceiptSlips(slips), style: ink.kind),
                      ],
                      const _Dashes(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(l10n.cardReceiptTotal, style: ink.total),
                          const Spacer(),
                          Text(l10n.minutesShort(minutes), style: ink.total),
                        ],
                      ),
                      const _Dashes(),
                      const SizedBox(height: 2),
                      Text(
                        signOff,
                        style: ink.signOff,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _Barcode(seed: start?.millisecondsSinceEpoch ?? 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The receipt's type: ink on paper, with figures that line up in columns.
class _Ink {
  _Ink(PosterType t)
    : heading = t
          .book(t.fa ? 20 : 21, Palette.night, FontWeight.w600)
          .copyWith(height: t.fa ? 1.6 : 1.25),
      title = t
          .book(17, Palette.night, FontWeight.w600)
          .copyWith(height: t.fa ? 1.7 : 1.3),
      small = _tab(t.ui(12, _faded)),
      line = _tab(t.ui(14, Palette.night)),
      value = _tab(t.ui(14, Palette.night, FontWeight.w500)),
      kind = t.ui(13, _faded),
      total = _tab(t.ui(20, Palette.night, FontWeight.w700)),
      signOff = t
          .ui(15, Palette.night, FontWeight.w500)
          .copyWith(height: t.fa ? 1.75 : 1.4);

  /// Thermal print that has faded a little: secondary lines.
  static const _faded = Color(0xFF5A6382);

  final TextStyle heading;
  final TextStyle title;
  final TextStyle small;
  final TextStyle line;
  final TextStyle value;
  final TextStyle kind;
  final TextStyle total;
  final TextStyle signOff;

  static TextStyle _tab(TextStyle s) =>
      s.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// One item on the receipt: what, and how much at the far end.
class _Line extends StatelessWidget {
  const _Line({
    required this.ink,
    required this.label,
    required this.value,
    this.icon,
  });

  final _Ink ink;
  final String label;
  final String value;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        if (icon case final icon?) ...[icon, const SizedBox(width: 6)],
        Expanded(
          child: Text(
            label,
            style: ink.line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: ink.value),
      ],
    ),
  );
}

/// The slip of thermal paper: torn into teeth at the top and the bottom,
/// with a soft shadow on the desk.
class _Paper extends StatelessWidget {
  const _Paper({required this.child});

  final Widget child;

  static const width = 276.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: CustomPaint(
      painter: const _PaperShadow(),
      child: ClipPath(
        clipper: const _Torn(),
        child: ColoredBox(
          color: Palette.paper,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// The paper's outline, its short edges torn into small teeth.
class _Torn extends CustomClipper<Path> {
  const _Torn();

  static const tooth = 6.0;
  static const depth = 4.0;

  @override
  Path getClip(Size size) => torn(size);

  static Path torn(Size size) {
    final n = (size.width / tooth).round();
    final step = size.width / n;
    final path = Path()..moveTo(0, depth);
    for (var i = 0; i < n; i++) {
      path
        ..lineTo(step * (i + 0.5), 0)
        ..lineTo(step * (i + 1), depth);
    }
    path.lineTo(size.width, size.height - depth);
    for (var i = n; i > 0; i--) {
      path
        ..lineTo(step * (i - 0.5), size.height)
        ..lineTo(step * (i - 1), size.height - depth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_Torn oldClipper) => false;
}

class _PaperShadow extends CustomPainter {
  const _PaperShadow();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _Torn.torn(size).shift(const Offset(0, 10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(_PaperShadow oldDelegate) => false;
}

/// A dashed rule across the receipt, the way a till prints one.
class _Dashes extends StatelessWidget {
  const _Dashes();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: SizedBox(
      height: 1.2,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    ),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.night.withValues(alpha: 0.55)
      ..strokeWidth = size.height;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + 3.5, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

/// The app's lit window, printed as the shop's logo.
class _LitWindow extends StatelessWidget {
  const _LitWindow();

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 26,
    decoration: BoxDecoration(
      color: Palette.night,
      borderRadius: BorderRadius.circular(3),
    ),
    alignment: Alignment.center,
    child: Container(
      width: 12,
      height: 15,
      decoration: BoxDecoration(
        color: Palette.lamp,
        borderRadius: BorderRadius.circular(1.5),
      ),
    ),
  );
}

/// A tea glass on its saucer, steaming: the Planned break, drawn in the
/// app's stroke (1.7, rounded) instead of an emoji.
class _TeaGlass extends StatelessWidget {
  const _TeaGlass();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 20,
    child: CustomPaint(painter: _TeaGlassPainter()),
  );
}

class _TeaGlassPainter extends CustomPainter {
  const _TeaGlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = Palette.night
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // The glass: a tulip, narrow at the waist, with the tea in it.
    final glass = Path()
      ..moveTo(w * 0.24, h * 0.40)
      ..cubicTo(w * 0.22, h * 0.58, w * 0.40, h * 0.62, w * 0.36, h * 0.86)
      ..lineTo(w * 0.64, h * 0.86)
      ..cubicTo(w * 0.60, h * 0.62, w * 0.78, h * 0.58, w * 0.76, h * 0.40);
    final tea = Path()
      ..moveTo(w * 0.25, h * 0.52)
      ..cubicTo(w * 0.28, h * 0.62, w * 0.40, h * 0.64, w * 0.37, h * 0.86)
      ..lineTo(w * 0.63, h * 0.86)
      ..cubicTo(w * 0.60, h * 0.64, w * 0.72, h * 0.62, w * 0.75, h * 0.52)
      ..close();
    canvas
      ..drawPath(tea, Paint()..color = const Color(0xFFB4622F))
      ..drawPath(glass, stroke)
      // The saucer.
      ..drawLine(
        Offset(w * 0.12, h * 0.94),
        Offset(w * 0.88, h * 0.94),
        stroke,
      );
    // Steam.
    for (final x in [0.42, 0.58]) {
      canvas.drawPath(
        Path()
          ..moveTo(w * x, h * 0.30)
          ..cubicTo(
            w * (x - 0.08),
            h * 0.22,
            w * (x + 0.08),
            h * 0.14,
            w * x,
            h * 0.04,
          ),
        stroke..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_TeaGlassPainter oldDelegate) => false;
}

/// A barcode at the foot, like any receipt's. It's decoration: the bars come
/// from when the Session started, so each night prints its own.
class _Barcode extends StatelessWidget {
  const _Barcode({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 34, child: CustomPaint(painter: _BarcodePainter(seed)));
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..color = Palette.night;
    const margin = 18.0;
    var x = margin;
    while (x < size.width - margin) {
      final bar = 1.0 + random.nextInt(3);
      if (x + bar > size.width - margin) break;
      canvas.drawRect(Rect.fromLTWH(x, 0, bar, size.height), paint);
      x += bar + 1.0 + random.nextInt(3);
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.seed != seed;
}
