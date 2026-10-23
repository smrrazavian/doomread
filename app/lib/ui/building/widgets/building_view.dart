import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// The user's tower at night: a ground floor with a door and one lit floor
/// per Finish above it, the newest on top. Laid out with start and end, so
/// the moon and the neighbour swap sides in Persian.
class BuildingView extends StatefulWidget {
  const BuildingView({
    required this.floors,
    this.highlighted,
    this.lightUp = false,
    this.maxFloors,
    super.key,
  });

  final int floors;

  /// Draws only this many floors from the top, leaving out the rest and the
  /// ground; null draws the whole tower.
  final int? maxFloors;

  /// Which floor, counted from the top, glows as the user's own.
  final int? highlighted;

  /// Lights the highlighted floor's windows one by one: the finishing moment.
  final bool lightUp;

  @override
  State<BuildingView> createState() => _BuildingViewState();
}

class _BuildingViewState extends State<BuildingView>
    with SingleTickerProviderStateMixin {
  late final _light = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: widget.lightUp ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.lightUp || _light.isCompleted || _light.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _light.value = 1;
    } else {
      _light.forward();
    }
  }

  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.floors.clamp(0, widget.maxFloors ?? widget.floors);
    return ExcludeSemantics(
      child: Stack(
        children: [
          const PositionedDirectional(
            end: 24,
            top: 4,
            child: SizedBox.square(
              dimension: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.paper,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const PositionedDirectional(
            start: 0,
            bottom: 0,
            child: SizedBox(
              width: 44,
              height: 72,
              child: ColoredBox(color: Palette.deep),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1,
              child: SizedBox(
                width: _towerWidth,
                child: Column(
                  children: [
                    for (var i = 0; i < shown; i++)
                      if (i == widget.highlighted)
                        AnimatedBuilder(
                          animation: _light,
                          builder: (_, _) => _Floor(lit: _light.value),
                        )
                      else
                        const _Floor(),
                    // A cut-off tower runs on below the frame.
                    if (shown == widget.floors) const _Ground(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _towerWidth = 152.0;
const _windows = 4;

/// One floor. [lit] is null for an ordinary floor, or how far the user's own
/// floor has lit up, from 0 to 1.
class _Floor extends StatelessWidget {
  const _Floor({this.lit});

  final double? lit;

  @override
  Widget build(BuildContext context) {
    final lit = this.lit;
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 3),
      color: lit == null ? Palette.wall : Palette.newFloor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < _windows; i++)
            _Window(
              color: lit == null
                  ? Palette.lamp
                  : Color.lerp(
                      Palette.raise,
                      Palette.me,
                      // Each window comes on a little after the one before.
                      ((lit * (_windows + 1)) - i).clamp(0, 1),
                    )!,
              glow: lit != null && lit > 0,
            ),
        ],
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window({required this.color, this.glow = false});

  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 22,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      boxShadow: [
        if (glow)
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8),
      ],
    ),
  );
}

/// The street-level floor, with the door on the start side.
class _Ground extends StatelessWidget {
  const _Ground();

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    color: Palette.wall,
    padding: const EdgeInsetsDirectional.only(start: 24),
    alignment: AlignmentDirectional.bottomStart,
    child: const SizedBox(
      width: 30,
      height: 30,
      child: ColoredBox(color: Palette.deep),
    ),
  );
}
