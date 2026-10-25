import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/calendar/view_models/calendar_view_model.dart';
import 'package:doomread/ui/calendar/widgets/day_sheet.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/settings_button.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Calendar: a month of days, each glowing from the bottom with that
/// day's focus time, with a legend under it. Months swipe; a day opens its
/// sheet.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (c) => CalendarViewModel(
      c.read<SessionRepository>(),
      c.read<WorkRepository>(),
    ),
    child: const _Calendar(),
  );
}

class _Calendar extends StatefulWidget {
  const _Calendar();

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  /// Page [_tonight] is tonight's month; those before it, earlier ones.
  static const _tonight = 1200;
  final _pages = PageController(initialPage: _tonight);

  /// Whether the legend shows the glow scale's minutes.
  bool _ticks = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final solarHijri = calendarOf(context).solarHijri;
    return Scaffold(
      appBar: AppBar(actions: const [SettingsButton()]),
      body: SafeArea(
        child: PageView.builder(
          controller: _pages,
          itemBuilder: (context, page) => _MonthPage(
            key: ValueKey(page),
            view: vm.month(page - _tonight, solarHijri: solarHijri),
            ticks: _ticks,
            onScale: () => setState(() => _ticks = !_ticks),
            onDay: (day, holds) => showDaySheet(
              context,
              day: day,
              holds: holds,
              reading: vm.readingOn(day),
            ),
          ),
        ),
      ),
    );
  }
}

/// One month: its title and summary, the grid, and the legend.
class _MonthPage extends StatelessWidget {
  const _MonthPage({
    required this.view,
    required this.ticks,
    required this.onScale,
    required this.onDay,
    super.key,
  });

  final CalendarMonthView view;
  final bool ticks;
  final VoidCallback onScale;
  final void Function(DateTime day, CalendarDay holds) onDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final month = view.month;
    final summary = [
      if (month.count > 0) l10n.calendarNightsLit(month.count),
      if (view.tasksDone > 0) l10n.calendarTasksDone(view.tasksDone),
      if (view.finishes > 0) l10n.calendarFinishes(view.finishes),
    ];
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMonthYear(context, month.calendarMonth),
                style: text.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                summary.isEmpty
                    ? l10n.calendarQuiet
                    : summary.join(l10n.calendarSeparator),
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _MonthGrid(view: view, onDay: onDay),
        const SizedBox(height: 14),
        _Legend(ticks: ticks, onScale: onScale),
      ],
    );
  }
}

/// The lamplight a day glows with at [t] of the way to two hours: a faint
/// amber at the least, the user's own warm light at the most.
Color glowColor(double t) => Color.fromRGBO(
  255,
  (196 + (226 - 196) * t).round(),
  (83 + (154 - 83) * t).round(),
  0.18 + 0.82 * t,
);

/// How far a day's [focus] is up the glow scale, capped at two hours.
double glowOf(Duration focus) =>
    (focus.inSeconds / const Duration(hours: 2).inSeconds).clamp(0.0, 1.0);

const _spine = Color(0xFFC0533F);

/// The grid, weekdays over it. Opening it is the screen's one orchestrated
/// moment: each day's glow rises in turn.
class _MonthGrid extends StatefulWidget {
  const _MonthGrid({required this.view, required this.onDay});

  final CalendarMonthView view;
  final void Function(DateTime day, CalendarDay holds) onDay;

  @override
  State<_MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<_MonthGrid>
    with SingleTickerProviderStateMixin {
  static const _lead = 250;
  static const _step = 30;
  static const _rise = 700;

  late final _rising = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: _lead + _step * widget.view.month.nights.length + _rise,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _rising.value = 1;
    } else if (_rising.isDismissed) {
      _rising.forward();
    }
  }

  @override
  void dispose() {
    _rising.dispose();
    super.dispose();
  }

  Animation<double> _riseOf(int i) {
    final total = _rising.duration!.inMilliseconds;
    final start = (_lead + _step * i) / total;
    return CurvedAnimation(
      parent: _rising,
      curve: Interval(
        start,
        start + _rise / total,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.view.month;
    final firstDay = calendarOf(context).firstDay;
    final narrow = MaterialLocalizations.of(context).narrowWeekdays;
    final mute = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Palette.mute);
    final lead = month.leadingDays(firstDay);
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  narrow[(firstDay + i) % 7],
                  textAlign: TextAlign.center,
                  style: mute,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: 58,
          ),
          itemCount: lead + month.nights.length,
          itemBuilder: (context, i) {
            if (i < lead) return const SizedBox.shrink();
            final day = month.nights[i - lead];
            final holds = widget.view.days[day]!;
            return _DayTile(
              key: ValueKey(day),
              day: day,
              holds: holds,
              read: month.isLit(day),
              today: day == month.tonight,
              rise: _riseOf(i - lead),
              onTap: () => widget.onDay(day, holds),
            );
          },
        ),
      ],
    );
  }
}

/// One day: its date, a glow from the bottom as tall and bright as its
/// focus time, and its marks. A dark day is just the tile and its date.
class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.holds,
    required this.read,
    required this.today,
    required this.rise,
    required this.onTap,
    super.key,
  });

  final DateTime day;
  final CalendarDay holds;

  /// Whether the user read or watched that night.
  final bool read;
  final bool today;
  final Animation<double> rise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final date = calendarOf(context).solarHijri
        ? toSolarHijri(day).day
        : day.day;
    final t = glowOf(holds.focus);
    final radius = BorderRadius.circular(12);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: radius,
          border: Border.all(
            color: today ? Palette.me : Palette.line,
            width: today ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              if (t > 0)
                Positioned.fill(
                  child: AnimatedBuilder(
                    key: const Key('glow'),
                    animation: rise,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: t * rise.value,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              glowColor(t).withValues(alpha: 0),
                              glowColor(t),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 5,
                start: 6,
                child: Text(
                  formatNumber(date, locale),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: today ? Palette.me : Palette.soft),
                ),
              ),
              if (read)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Container(
                    key: const Key('spine'),
                    width: 4,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _spine,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              if (holds.finishes > 0)
                const PositionedDirectional(
                  top: 5,
                  end: 13,
                  child: _Flag(key: Key('flag')),
                ),
              if (holds.tasksDone > 0 || holds.planned > 0)
                PositionedDirectional(
                  bottom: 6,
                  start: 6,
                  child: Row(
                    children: [
                      for (var i = 0; i < holds.tasksDone && i < 4; i++)
                        const _Dot(key: Key('dot')),
                      for (var i = 0; i < holds.planned && i < 4; i++)
                        const _Dot(key: Key('planned'), outlined: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A Task's dot: filled once Done, outlined while it's still planned.
class _Dot extends StatelessWidget {
  const _Dot({this.outlined = false, super.key});

  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    margin: const EdgeInsetsDirectional.only(end: 3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: outlined ? null : Palette.lamp,
      border: outlined ? Border.all(color: Palette.lamp) : null,
    ),
  );
}

/// The small flag on a day something was Finished.
class _Flag extends StatelessWidget {
  const _Flag({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(9, 9), painter: _FlagPainter());
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // The mockup's flag, drawn on an 8 by 8 grid.
    final s = size.width / 8;
    final path = Path()
      ..moveTo(1 * s, 8 * s)
      ..lineTo(1 * s, 1 * s)
      ..lineTo(6 * s, 1 * s)
      ..lineTo(5 * s, 3 * s)
      ..lineTo(6 * s, 5 * s)
      ..lineTo(1 * s, 5 * s);
    canvas
      ..drawPath(path, Paint()..color = Palette.me)
      ..drawPath(
        path,
        Paint()
          ..color = const Color(0xFF2A1F05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5 * s,
      );
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => false;
}

/// The legend under the grid: the glow scale, whose minutes show on tap,
/// then what the dot, the spine and the flag mean.
class _Legend extends StatelessWidget {
  const _Legend({required this.ticks, required this.onScale});

  final bool ticks;
  final VoidCallback onScale;

  /// The ticks on the scale and how much of it each one closes, as a share
  /// of two hours: 30 minutes, then 1 hour, then 2.
  static const _spans = [1, 1, 2];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Palette.soft);
    final mute = small?.copyWith(color: Palette.mute);
    final labels = [
      l10n.calendarTick30m,
      l10n.calendarTick1h,
      l10n.calendarTick2h,
    ];
    // The ends of the scale, again but unseen under it, so the ticks line
    // up with the bar between them.
    Widget scale(Widget bar, {bool shown = true}) => Row(
      children: [
        Opacity(
          opacity: shown ? 1 : 0,
          child: Text(l10n.calendarLegendNone, style: mute),
        ),
        const SizedBox(width: 8),
        Expanded(child: bar),
        const SizedBox(width: 8),
        Opacity(
          opacity: shown ? 1 : 0,
          child: Text(l10n.calendarLegendMost, style: mute),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Palette.deep,
        border: Border.all(color: Palette.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calendarLegendTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onScale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.calendarLegendFocus,
                  style: small?.copyWith(color: Palette.paper),
                ),
                const SizedBox(height: 4),
                scale(
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        colors: [Palette.panel, glowColor(0.5), glowColor(1)],
                      ),
                    ),
                  ),
                ),
                if (ticks)
                  scale(
                    shown: false,
                    Row(
                      children: [
                        for (final (i, span) in _spans.indexed)
                          Expanded(
                            flex: span,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(labels[i], style: mute),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Key(mark: const _Dot(), label: l10n.calendarLegendDot),
              _Key(
                mark: Container(
                  width: 4,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _spine,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                label: l10n.calendarLegendSpine,
              ),
              _Key(mark: const _Flag(), label: l10n.calendarLegendFlag),
            ],
          ),
        ],
      ),
    );
  }
}

/// One mark in the legend and what it means.
class _Key extends StatelessWidget {
  const _Key({required this.mark, required this.label});

  final Widget mark;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      mark,
      const SizedBox(width: 6),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Palette.soft),
      ),
    ],
  );
}
