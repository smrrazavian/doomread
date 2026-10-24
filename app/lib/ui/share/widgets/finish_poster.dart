import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/building/widgets/building_view.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/core/work_text.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
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
  static const Size size = PosterCanvas.size;

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
    final type = PosterType(fa: fa);
    final evenings = finish.evenings;
    final minutes = finish.longestStretch.inMinutes;
    final note = this.note?.trim();

    return PosterCanvas(
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: PosterSky())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 28, 24, 0),
                child: Wordmark(l10n.appTitle, type.mark),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // One heading in the book face: "I finished",
                      // then the title, larger.
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${l10n.sharePosterFinished}\n',
                              style: type.finished,
                            ),
                            TextSpan(
                              // Isolated, so a Latin title in Persian
                              // (or the reverse) can't pull the
                              // guillemets around.
                              text: l10n.sharePosterTitle(
                                '\u2068${finish.work.title}\u2069',
                              ),
                            ),
                          ],
                        ),
                        style: type.title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (finish.work.author.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          finish.work.author,
                          style: type.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
      // Where the new floor is, on the poster.
      final width = box.maxWidth;
      final floorRect = lit == null
          ? null
          : Rect.fromLTWH(
              width / 2 - 76 * k,
              top + (_top + lit * _floor) * k,
              152 * k,
              44 * k,
            );
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (floorRect != null)
            Positioned.fill(child: CustomPaint(painter: _Spill(floorRect))),
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
          if (floorRect != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _Shade(floorRect, top + _top * k, room),
              ),
            ),
        ],
      );
    },
  );
}

/// The new floor's light on the night around it: a warm halo hugging the
/// floor and a wide, faint spill onto the sky.
class _Spill extends CustomPainter {
  const _Spill(this.floor);

  final Rect floor;

  /// How far the light reaches into the sky.
  static const _reach = 190.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = floor.center;
    canvas
      ..drawCircle(
        c,
        _reach,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Palette.lamp.withValues(alpha: 0.22),
              Palette.lamp.withValues(alpha: 0.06),
              Palette.lamp.withValues(alpha: 0),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(Rect.fromCircle(center: c, radius: _reach)),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(floor.inflate(6), const Radius.circular(8)),
        Paint()
          ..color = Palette.lamp.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
  }

  @override
  bool shouldRepaint(_Spill old) => old.floor != floor;
}

/// Lets the older floors sit back in the night, so the new one is clearly
/// the brightest.
class _Shade extends CustomPainter {
  const _Shade(this.floor, this.top, this.bottom);

  final Rect floor;

  /// Where the Building's top floor starts, and where the street is.
  final double top;
  final double bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = Palette.night.withValues(alpha: 0.32);
    // The floors above and below, with the gaps between them.
    final above = Rect.fromLTRB(floor.left, top, floor.right, floor.top);
    final below = Rect.fromLTRB(floor.left, floor.bottom, floor.right, bottom);
    canvas
      ..save()
      ..clipRect(Offset.zero & Size(size.width, bottom))
      ..drawRect(above, shade)
      ..drawRect(below, shade)
      ..restore();
  }

  @override
  bool shouldRepaint(_Shade old) =>
      old.floor != floor || old.top != top || old.bottom != bottom;
}

/// The numbers worth a flex, side by side with a hairline between them.
class _Tallies extends StatelessWidget {
  const _Tallies({required this.type, required this.tallies});

  final PosterType type;
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
  final PosterType type;

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
