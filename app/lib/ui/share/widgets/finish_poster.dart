import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/building/widgets/building_view.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

/// The Finish as a story-sized poster: the user's Building on a night sky
/// with the new floor lit, what it took, and maybe their last Note.
///
/// It's laid out on a fixed [size] canvas, whatever the device, and drawn
/// at three times that for a 1080×1920 image. Persian gets its own layout:
/// right to left, Persian digits, and Naskh for the title and the Note.
class FinishPoster extends StatelessWidget {
  const FinishPoster({
    required this.finish,
    required this.floors,
    required this.floor,
    required this.urgesLetPass,
    this.note,
    super.key,
  });

  /// The canvas, in logical pixels; the image is three times this.
  static const size = Size(360, 640);

  final Finish finish;

  /// How many floors the Building has, and which one, from the top, is
  /// this Finish.
  final int floors;
  final int floor;

  final int urgesLetPass;

  /// The Note to quote; null leaves the block out.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final fa = locale.languageCode == 'fa';
    final type = _PosterType(fa: fa);
    final evenings = finish.evenings;
    final minutes = finish.longestStretch.inMinutes;
    final note = this.note?.trim();

    return MediaQuery(
      // The same poster on every phone: no system font scale or bold text.
      data: const MediaQueryData(
        size: size,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: SizedBox.fromSize(
        size: size,
        child: Material(
          type: MaterialType.transparency,
          child: ClipRect(
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _Sky())),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        24,
                        28,
                        24,
                        0,
                      ),
                      child: _Wordmark(l10n.appTitle, type),
                    ),
                    Expanded(
                      child: _Tower(floors: floors, floor: floor),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Palette.deep,
                        border: Border(
                          top: BorderSide(color: Palette.line, width: 1.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          24,
                          24,
                          24,
                          32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.sharePosterFinished, style: type.lead),
                            const SizedBox(height: 4),
                            Text(
                              // Isolated, so a Latin title in Persian (or the
                              // reverse) can't pull the guillemets around.
                              l10n.sharePosterTitle(
                                '\u2068${finish.work.title}\u2069',
                              ),
                              style: type.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (finish.work.author.trim().isNotEmpty)
                              Text(
                                finish.work.author,
                                style: type.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (evenings > 0) ...[
                              const SizedBox(height: 12),
                              Text(_length(context, l10n), style: type.body),
                            ],
                            if (minutes > 0 || urgesLetPass > 0) ...[
                              const SizedBox(height: 20),
                              _Tallies(
                                type: type,
                                tallies: [
                                  if (minutes > 0)
                                    (
                                      l10n.minutesShort(minutes),
                                      l10n.longestStretchLabel,
                                    ),
                                  if (urgesLetPass > 0)
                                    (
                                      formatNumber(urgesLetPass, locale),
                                      l10n.sharePosterUrges(urgesLetPass),
                                    ),
                                ],
                              ),
                            ],
                            if (note != null && note.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _Note(note, type),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "245 pages over 3 evenings", in the Work's own unit.
  String _length(BuildContext context, AppLocalizations l10n) {
    final (n, evenings) = (finish.pages, finish.evenings);
    return switch (finish.work.kind.unit) {
      WorkUnit.page => l10n.sharePosterPages(n, evenings),
      WorkUnit.episode => l10n.sharePosterEpisodes(n, evenings),
      WorkUnit.second => l10n.sharePosterTime(
        formatAmount(context, finish.work, n),
        evenings,
      ),
    };
  }
}

/// The poster's type, set apart from the app theme so it can't drift with
/// it. Persian has its own faces and taller lines, and no letter spacing.
class _PosterType {
  _PosterType({required bool fa})
    : lead = _ui(fa, 15, Palette.lamp, FontWeight.w500),
      title = TextStyle(
        fontFamily: fa ? 'NotoNaskhArabic' : 'Literata',
        fontFamilyFallback: [if (fa) 'Literata' else 'NotoNaskhArabic'],
        fontSize: fa ? 27 : 30,
        height: fa ? 1.6 : 1.2,
        fontWeight: FontWeight.w500,
        fontVariations: const [FontVariation.weight(500)],
        letterSpacing: 0,
        color: Palette.paper,
      ),
      author = _ui(fa, 14, Palette.mute, FontWeight.w400),
      body = _ui(fa, 15, Palette.soft, FontWeight.w400),
      number = TextStyle(
        fontFamily: fa ? 'VazirmatnUI' : 'Literata',
        fontFamilyFallback: [if (fa) 'BricolageGrotesque' else 'VazirmatnUI'],
        fontSize: fa ? 26 : 28,
        height: 1.25,
        fontWeight: fa ? FontWeight.w700 : FontWeight.w500,
        fontVariations: fa ? null : const [FontVariation.weight(500)],
        letterSpacing: 0,
        color: Palette.me,
      ),
      label = _ui(fa, 13, Palette.mute, FontWeight.w400),
      note = TextStyle(
        fontFamily: fa ? 'NotoNaskhArabic' : 'Literata',
        fontFamilyFallback: [if (fa) 'Literata' else 'NotoNaskhArabic'],
        fontSize: fa ? 16 : 17,
        height: fa ? 1.85 : 1.5,
        letterSpacing: 0,
        color: Palette.paper,
      ),
      mark = _ui(fa, 14, Palette.paper, FontWeight.w500);

  final TextStyle lead;
  final TextStyle title;
  final TextStyle author;
  final TextStyle body;
  final TextStyle number;
  final TextStyle label;
  final TextStyle note;
  final TextStyle mark;

  static TextStyle _ui(bool fa, double size, Color color, FontWeight w) =>
      TextStyle(
        fontFamily: fa ? 'VazirmatnUI' : 'BricolageGrotesque',
        fontFamilyFallback: [if (fa) 'BricolageGrotesque' else 'VazirmatnUI'],
        fontSize: size,
        height: fa ? 1.7 : 1.4,
        fontWeight: w,
        fontVariations: [FontVariation.weight(w.value.toDouble())],
        letterSpacing: 0,
        color: color,
      );
}

/// A small lit window and the app's name: the icon, in words.
class _Wordmark extends StatelessWidget {
  const _Wordmark(this.name, this.type);

  final String name;
  final _PosterType type;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 12,
        decoration: BoxDecoration(
          color: Palette.lamp,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: [
            BoxShadow(
              color: Palette.lamp.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(name, style: type.mark),
    ],
  );
}

/// The Building, standing on the street at the bottom of the sky, with as
/// many floors as fit; the new one glows.
class _Tower extends StatelessWidget {
  const _Tower({required this.floors, required this.floor});

  final int floors;
  final int floor;

  // BuildingView's measures: room for the moon, each floor, the ground.
  static const _top = 32.0;
  static const _floor = 47.0;
  static const _ground = 44.0;

  /// The Building drawn larger than in the app: on the poster it's the hero.
  static const _scale = 1.25;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final room = box.maxHeight;
      final natural = _top + floors * _floor + _ground;
      // As large as the sky allows, up to the hero size; a Building too
      // tall even at its app size runs on below the street, at the hero size.
      final k = natural <= room ? math.min(_scale, room / natural) : _scale;
      final whole = natural * k;
      final fits = whole <= room + 0.5;
      // A tall Building runs on below the street, out of the frame.
      final shown = fits
          ? floors
          : ((room / k - _top) / _floor).ceil().clamp(1, floors);
      final top = fits ? room - whole : 0.0;
      final lit = floor < shown ? floor : null;
      return Stack(
        children: [
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                // Narrower than the poster, so the scaled moon stays on it.
                width: 280,
                child: Transform.scale(
                  scale: k,
                  alignment: Alignment.topCenter,
                  child: BuildingView(
                    floors: floors,
                    highlighted: lit,
                    maxFloors: shown,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// The numbers worth a flex, side by side with a hairline between them.
class _Tallies extends StatelessWidget {
  const _Tallies({required this.type, required this.tallies});

  final _PosterType type;
  final List<(String, String)> tallies;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (number, label)) in tallies.indexed) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: Palette.line,
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(number, style: type.number),
              Text(label, style: type.label),
            ],
          ),
        ],
      ],
    ),
  );
}

/// The user's Note, in the book face, set by its own script's direction:
/// an English Note on a Persian poster still reads left to right.
class _Note extends StatelessWidget {
  const _Note(this.note, this.type);

  final String note;
  final _PosterType type;

  @override
  Widget build(BuildContext context) {
    final rtl = Bidi.detectRtlDirectionality(note);
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 14),
      decoration: const BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: Palette.lamp, width: 2),
        ),
      ),
      child: Text(
        note,
        style: type.note,
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        textAlign: TextAlign.start,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The night: deep at the top, a little lighter toward the street, with a
/// few stars. They're placed by a fixed seed, so every poster has the same.
class _Sky extends CustomPainter {
  const _Sky();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1426), Palette.deep, Palette.night],
          stops: [0, 0.35, 0.62],
        ).createShader(rect),
    );
    final random = math.Random(1980);
    final star = Paint();
    for (var i = 0; i < 46; i++) {
      final at = Offset(
        random.nextDouble() * size.width,
        24 + random.nextDouble() * size.height * 0.42,
      );
      final r = 0.5 + random.nextDouble() * 0.9;
      star.color = Palette.paper.withValues(
        alpha: 0.25 + random.nextDouble() * 0.5,
      );
      canvas.drawCircle(at, r, star);
    }
  }

  @override
  bool shouldRepaint(_Sky oldDelegate) => false;
}
