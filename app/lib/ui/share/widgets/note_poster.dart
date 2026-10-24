import 'dart:math' as math;

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/share/widgets/poster_canvas.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

/// One Note, on a sheet of paper taped under the lamp, with the
/// Work's «title» under it. No numbers: it's the user's own sentence, and
/// only the one Note they chose to share.
///
/// The Note keeps its own script's direction, so an English Note on a
/// Persian card still reads left to right.
class NotePoster extends StatelessWidget {
  const NotePoster({required this.note, required this.work, super.key});

  final String note;
  final Work work;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fa = isPersian(context);
    final type = PosterType(fa: fa);
    final note = this.note.trim();
    final rtl = Bidi.detectRtlDirectionality(note);
    // A short Note is set large; a long one steps down so it still fits.
    final size = switch (note.length) {
      <= 70 => 23.0,
      <= 140 => 20.0,
      _ => 17.0,
    };
    final noteStyle = type
        .book(size, Palette.night)
        .copyWith(height: rtl ? 1.9 : 1.5);

    return PosterCanvas(
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: PosterSky(stars: 40, starDepth: 0.9)),
          ),
          const Positioned.fill(
            child: CustomPaint(
              painter: LampGlow(at: Offset(0.5, 0.45), reach: 320),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 26, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wordmark(l10n.appTitle, type.mark),
                ),
                Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: (fa ? 1 : -1) * 2 * math.pi / 180,
                      child: _Sheet(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              note,
                              style: noteStyle,
                              textDirection: rtl
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              textAlign: TextAlign.start,
                              maxLines: 9,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              l10n.sharePosterTitle(
                                '\u2068${work.title}\u2069',
                              ),
                              style: type
                                  .book(15, Palette.night, FontWeight.w600)
                                  .copyWith(height: fa ? 1.7 : 1.3),
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (work.author.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                work.author,
                                style: type.ui(12, const Color(0xFF5A6382)),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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

/// A sheet of paper with a strip of tape holding it up.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      CustomPaint(
        painter: const _Shadow(),
        child: Container(
          width: 296,
          decoration: BoxDecoration(
            color: Palette.paper,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 34),
            child: child,
          ),
        ),
      ),
      // The tape, a little askew, over the top edge.
      Positioned(
        top: -12,
        left: 0,
        right: 0,
        child: Center(
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              width: 92,
              height: 26,
              color: const Color(0xFFF3D88A).withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    ],
  );
}

/// The paper's soft shadow on the night.
class _Shadow extends CustomPainter {
  const _Shadow();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    (Offset.zero & size).shift(const Offset(0, 10)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
  );

  @override
  bool shouldRepaint(_Shadow oldDelegate) => false;
}
