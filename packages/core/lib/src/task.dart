import 'package:doomread_core/src/calendar.dart';

/// Something the user intends to get done: a kind of Work, with a name, the
/// day it's planned for and a rough estimate, both optional. Done is stored,
/// not worked out, since a Task has no Position to reach an end with.
class Task {
  const Task({
    required this.id,
    required this.name,
    this.day,
    this.estimate,
    this.doneAt,
  });

  final String id;
  final String name;

  /// The day it's planned for, as a date; null for no day in particular.
  final DateTime? day;

  /// About how long it takes. Only ever shown; it's no Aim or deadline.
  final Duration? estimate;

  /// When it was Done; null while it isn't.
  final DateTime? doneAt;

  bool get done => doneAt != null;
}

/// The Tasks on Today at [now]: those Done today, in the order they were
/// Done, then the undone ones planned for today, an earlier day or none, in
/// the order of [tasks]. An undone Task from an earlier day just carries
/// over, with nothing to mark it. Days follow [eveningOf], so they turn
/// over at 4 in the morning.
List<Task> tasksToday(Iterable<Task> tasks, DateTime now) {
  final today = eveningOf(now);
  return [
    ...tasks.where((t) => t.done && eveningOf(t.doneAt!) == today).toList()
      ..sort((a, b) => a.doneAt!.compareTo(b.doneAt!)),
    for (final t in tasks)
      if (!t.done && (t.day == null || !t.day!.isAfter(today))) t,
  ];
}

/// The Task to start next among [tasks]: the first one not Done.
Task? nextTask(Iterable<Task> tasks) => tasks.where((t) => !t.done).firstOrNull;
