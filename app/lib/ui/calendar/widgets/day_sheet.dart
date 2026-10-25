import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/calendar/view_models/calendar_view_model.dart';
import 'package:doomread/ui/core/date_format.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// Opens [day]'s sheet: its date, its focus time, the Tasks Done, what was
/// read or watched and how far, and that night's Notes. Only what the day
/// holds is shown; an empty day says so plainly.
Future<void> showDaySheet(
  BuildContext context, {
  required DateTime day,
  required CalendarDay holds,
  required DayReading reading,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Palette.panel,
  builder: (context) => _DaySheet(day: day, holds: holds, reading: reading),
);

class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.day,
    required this.holds,
    required this.reading,
  });

  final DateTime day;
  final CalendarDay holds;
  final DayReading reading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final minutes = holds.focus.inMinutes;
    final lines = [
      if (minutes >= 60)
        l10n.calendarFocusHours(minutes ~/ 60, minutes % 60)
      else if (minutes > 0)
        l10n.calendarFocusMinutes(minutes),
      if (holds.tasksDone > 0) l10n.calendarDayTasksDone(holds.tasksDone),
      if (holds.planned > 0) l10n.calendarDayPlanned(holds.planned),
      for (final (:work, :covered) in reading.works)
        [
          l10n.calendarDayWork(work.kind.name, work.title),
          if (covered != null && covered > 0) _howFar(context, work, covered),
        ].join(l10n.calendarSeparator),
    ];
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatWeekdayDayMonth(context, day),
              style: text.titleLarge?.copyWith(fontFamily: bookFamily(context)),
            ),
            if (lines.isEmpty && reading.notes.isEmpty)
              _line(context, l10n.calendarDayQuiet),
            for (final l in lines) _line(context, l),
            for (final note in reading.notes)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsetsDirectional.only(start: 10),
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: Palette.lamp, width: 2),
                  ),
                ),
                child: Text(
                  note,
                  style: text.bodyLarge?.copyWith(
                    fontFamily: bookFamily(context),
                    fontStyle: isPersian(context) ? null : FontStyle.italic,
                    color: Palette.paper,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String s) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      s,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Palette.soft),
    ),
  );

  /// How far [work] went that day, in its own unit.
  static String _howFar(BuildContext context, Work work, int covered) {
    final l10n = AppLocalizations.of(context);
    return switch (work.kind.unit) {
      WorkUnit.page => l10n.calendarPages(covered),
      WorkUnit.episode => l10n.calendarEpisodes(covered),
      // Time listened or watched, not a timestamp.
      WorkUnit.second => l10n.minutesShort(
        minutesUp(Duration(seconds: covered)),
      ),
    };
  }
}
