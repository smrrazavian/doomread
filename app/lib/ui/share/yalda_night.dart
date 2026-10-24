import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/ui/core/yalda.dart';
import 'package:doomread_core/doomread_core.dart';

/// Shab-e Yalda as the journal has it so far: tonight's date, the whole
/// minutes read across tonight's Sessions, the Work of the last of them
/// (null before any), and the House with tonight's last Session as the
/// user's Window.
typedef YaldaNight = ({
  DateTime evening,
  int minutes,
  Work? work,
  List<HouseWindow> house,
});

/// Tonight's [YaldaNight] from every Session in [records], measured at
/// [now]; null on any other night. Whether a Work is current doesn't
/// matter, so a Work finished tonight still counts.
YaldaNight? yaldaNight(Iterable<SessionRecord> records, DateTime now) {
  if (!yaldaAt(now)) return null;
  final evening = eveningOf(now);
  final tonight = [
    for (final r in records)
      if (r.at(now) case final s
          when s.startedAt != null &&
              !s.startedAt!.isAfter(now) &&
              eveningOf(s.startedAt!) == evening)
        (record: r, session: s),
  ]..sort((a, b) => a.session.startedAt!.compareTo(b.session.startedAt!));
  final last = tonight.lastOrNull?.record;
  return (
    evening: evening,
    minutes: tonight
        .fold(
          Duration.zero,
          (sum, t) => sum + t.session.readingBetween(t.session.startedAt, null),
        )
        .inMinutes,
    work: last?.road.work,
    house: houseWindows(
      now: now,
      before: [
        for (final r in records)
          if (r.id != last?.id) ?r.at(now).startedAt,
      ],
    ),
  );
}
