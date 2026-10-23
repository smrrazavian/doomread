import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// The Road drawn as a track: done part, Checkpoint ticks, "you are here" and
/// the finish flag. Positions are start-relative, so it mirrors in Persian.
class RoadView extends StatelessWidget {
  const RoadView({required this.road, super.key});

  final Road road;

  @override
  Widget build(BuildContext context) {
    final total = road.work.totalPages;
    return Semantics(
      // ۵۸٪ in Persian, 58% in English.
      label: NumberFormat.percentPattern(
        Localizations.localeOf(context).languageCode,
      ).format(road.progress),
      child: SizedBox(
        height: 28,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _bar(0, w, Palette.raise),
                _bar(0, w * road.progress, Palette.lamp),
                for (final c in road.work.checkpoints)
                  PositionedDirectional(
                    start: w * c / total - 1,
                    top: 8,
                    child: Container(
                      width: 2,
                      height: 12,
                      color: c <= road.position
                          ? Palette.tickPassed
                          : Palette.tickAhead,
                    ),
                  ),
                PositionedDirectional(
                  start: w * road.progress - 9,
                  top: 5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Palette.me,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: -4,
                  top: 0,
                  // The flag faces back along the Road in either direction.
                  child: Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: const Icon(
                      Icons.flag,
                      size: 20,
                      color: Palette.paper,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bar(double start, double width, Color color) => PositionedDirectional(
    start: start,
    top: 12,
    child: Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
