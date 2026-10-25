import 'package:doomread_core/src/calendar.dart';

/// What the user did during a Session, as stored in the journal.
///
/// A Planned break starts with [breakStart] and ends with [breakEnd] (or a
/// Resume, or Stop). A [nudge] moves the offered Planned break later. An
/// [urge] is the "not yet" screen coming up; it ends as [letPass] or [slip].
/// A [checkpoint] is the user saying they reached the next Checkpoint.
/// A [reopen] undoes the Stop just before it ("Stopped by mistake?").
enum SessionEventKind {
  start,
  pause,
  resume,
  stop,
  breakStart,
  breakEnd,
  nudge,
  urge,
  letPass,
  slip,
  checkpoint,
  reopen,
}

/// One timestamped entry in a Session's journal. Entries are only ever
/// appended; everything else is derived from them by [Session.fromEvents].
class SessionEvent {
  const SessionEvent(this.kind, this.at, {this.page});

  final SessionEventKind kind;
  final DateTime at;

  /// The Position it put on record: where a [SessionEventKind.start] began,
  /// or the Checkpoint a [SessionEventKind.checkpoint] reached. Null for
  /// every other kind, and for a Start from before pages were kept.
  final int? page;
}

/// What ended a Stretch.
enum StretchEnd { pause, stop, plannedBreak, slip }

/// A Planned break the user took: when it started and, once they're back,
/// when it ended.
typedef BreakTaken = ({DateTime start, DateTime? end});

/// A Checkpoint the user said they reached, and when.
typedef CheckpointReached = ({DateTime at, int page});

/// Unbroken Session time with the timer running.
class Stretch {
  const Stretch(this.start, this.end, this.endedBy);

  final DateTime start;

  /// When it ended, or the clock's now while it's still running.
  final DateTime end;

  /// Null while the Stretch is still running.
  final StretchEnd? endedBy;

  bool get running => endedBy == null;

  /// Never negative, even if the clock went backwards.
  Duration get length {
    final d = end.difference(start);
    return d.isNegative ? Duration.zero : d;
  }
}

/// One sitting with one Work, derived from its journal.
class Session {
  /// The reducer: replays [events] in time order, measuring a running Stretch
  /// up to [now] (the injected clock).
  ///
  /// The journal may hold entries that don't apply, say a second Pause from a
  /// double tap or anything after Stop. Those are ignored, not errors.
  factory Session.fromEvents(
    Iterable<SessionEvent> events, {
    required DateTime now,
  }) {
    // A stable sort, so entries with the same timestamp keep journal order.
    final indexed = events.indexed.toList()
      ..sort((a, b) {
        final byTime = a.$2.at.compareTo(b.$2.at);
        return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
      });

    DateTime? startedAt;
    int? startPage;
    DateTime? runningSince;
    var stopped = false;
    var urgeOpen = false;
    var slipped = false;
    var letPass = 0;
    final stretches = <Stretch>[];
    final breaks = <BreakTaken>[];
    final nudges = <DateTime>[];
    final checkpoints = <CheckpointReached>[];
    bool onBreak() => breaks.isNotEmpty && breaks.last.end == null;
    void close(DateTime at, StretchEnd by) {
      if (runningSince == null) return;
      stretches.add(Stretch(runningSince!, at, by));
      runningSince = null;
    }

    void endBreak(DateTime at) {
      if (!onBreak()) return;
      breaks.last = (start: breaks.last.start, end: at);
      runningSince = at;
    }

    for (final (_, e) in indexed) {
      // After Stop only a Reopen counts. It takes the Stop back, so a
      // Stretch the Stop ended goes on, as if it never stopped.
      if (stopped) {
        if (e.kind != SessionEventKind.reopen) continue;
        stopped = false;
        if (stretches.lastOrNull case Stretch(
          :final start,
          endedBy: StretchEnd.stop,
        )) {
          stretches.removeLast();
          runningSince = start;
        }
        continue;
      }
      switch (e.kind) {
        case SessionEventKind.start:
          if (startedAt != null) continue;
          startedAt = e.at;
          startPage = e.page;
          runningSince = e.at;
        case _ when startedAt == null:
          continue;
        case SessionEventKind.pause:
          close(e.at, StretchEnd.pause);
        case SessionEventKind.resume when onBreak():
        case SessionEventKind.breakEnd:
          endBreak(e.at);
        case SessionEventKind.resume:
          runningSince ??= e.at;
          slipped = false;
        case SessionEventKind.breakStart:
          if (onBreak()) continue;
          close(e.at, StretchEnd.plannedBreak);
          breaks.add((start: e.at, end: null));
          urgeOpen = false;
          slipped = false;
        // Only while a Stretch runs: a Pause is never a failure, so it has
        // nothing for a Slip to end.
        case SessionEventKind.urge:
          if (runningSince != null) urgeOpen = true;
        // Letting it pass leaves the Stretch running: riding out the Urge is
        // the point.
        case SessionEventKind.letPass:
          if (urgeOpen) letPass++;
          urgeOpen = false;
        case SessionEventKind.slip:
          if (!urgeOpen) continue;
          urgeOpen = false;
          close(e.at, StretchEnd.slip);
          slipped = true;
        case SessionEventKind.nudge:
          if (!onBreak()) nudges.add(e.at);
        case SessionEventKind.checkpoint:
          if (e.page case final page? when !onBreak()) {
            checkpoints.add((at: e.at, page: page));
          }
        // Only after a Stop, above.
        case SessionEventKind.reopen:
          continue;
        case SessionEventKind.stop:
          close(e.at, StretchEnd.stop);
          endBreak(e.at);
          runningSince = null;
          urgeOpen = false;
          slipped = false;
          stopped = true;
      }
    }
    if (runningSince != null) stretches.add(Stretch(runningSince!, now, null));
    return Session._(
      startedAt,
      startPage,
      stretches,
      breaks,
      nudges,
      checkpoints,
      stopped: stopped,
      urgeOpen: urgeOpen,
      slipped: slipped,
      urgesLetPass: letPass,
    );
  }

  Session._(
    this.startedAt,
    this.startPage,
    List<Stretch> stretches,
    List<BreakTaken> breaks,
    List<DateTime> nudges,
    List<CheckpointReached> checkpoints, {
    required this.stopped,
    required this.urgeOpen,
    required this.slipped,
    required this.urgesLetPass,
  }) : stretches = List.unmodifiable(stretches),
       breaks = List.unmodifiable(breaks),
       nudges = List.unmodifiable(nudges),
       checkpoints = List.unmodifiable(checkpoints);

  /// When the Session started; null if the journal has no Start.
  final DateTime? startedAt;

  /// The Position the Session started at; null if its Start didn't say.
  final int? startPage;

  /// In order, the last one possibly still running.
  final List<Stretch> stretches;

  /// The Planned breaks taken, in order; the last one may still be on.
  final List<BreakTaken> breaks;

  /// When the user nudged the offered Planned break later, in order. Only
  /// those while reading or paused count.
  final List<DateTime> nudges;

  /// The Checkpoints the user marked done, in order. Only those while
  /// reading or paused count, as for [nudges].
  final List<CheckpointReached> checkpoints;

  final bool stopped;

  /// The "not yet" screen is up: an Urge neither let pass nor slipped yet.
  final bool urgeOpen;

  /// The user went on into a Watched app and hasn't resumed since. Coming
  /// back, they see the kind After-a-slip screen.
  final bool slipped;

  /// How many Urges ended as Let pass. Only one that was open counts, so a
  /// double tap, or a Let pass with no Urge before it, can't add another.
  final int urgesLetPass;

  /// Started, not stopped, no Stretch running, and not on a Planned break.
  bool get paused =>
      startedAt != null &&
      !stopped &&
      !onBreak &&
      (stretches.lastOrNull?.endedBy != null);

  /// On a Planned break right now.
  bool get onBreak => breaks.isNotEmpty && breaks.last.end == null;

  /// Reading time since the last Planned break ended, or since the Start.
  Duration get readingSinceBreak =>
      readingBetween(breaks.lastOrNull?.end ?? startedAt, null);

  /// The time in Stretches that started from [from] (inclusive) until [to],
  /// or until now when [to] is null. No Stretch spans a Planned break, so
  /// between breaks this is all the reading done there.
  Duration readingBetween(DateTime? from, DateTime? to) => stretches
      .where(
        (s) =>
            from != null &&
            !s.start.isBefore(from) &&
            (to == null || s.start.isBefore(to)),
      )
      .fold(Duration.zero, (sum, s) => sum + s.length);

  /// The time in Stretches between [from] and [to], each cut to fit, so a
  /// Stretch still running at [to] counts only up to it.
  Duration readingIn(DateTime? from, DateTime to) {
    if (from == null) return Duration.zero;
    var sum = Duration.zero;
    for (final s in stretches) {
      final start = s.start.isAfter(from) ? s.start : from;
      final end = s.end.isBefore(to) ? s.end : to;
      if (end.isAfter(start)) sum += end.difference(start);
    }
    return sum;
  }

  /// All the time in Stretches: the Session's reading, without its
  /// Pauses or Planned breaks.
  Duration get reading => readingBetween(startedAt, null);

  /// How many Urges ended as a Slip: each ended a Stretch.
  int get slips => stretches.where((s) => s.endedBy == StretchEnd.slip).length;

  /// The Stretch running now, if any.
  Stretch? get current {
    final last = stretches.lastOrNull;
    return last != null && last.running ? last : null;
  }

  /// The longest Stretch in this Session, running or not.
  Duration get longestStretch => stretches.fold(
    Duration.zero,
    (best, s) => s.length > best ? s.length : best,
  );
}

/// The Longest stretch across [sessions], all of one kind of Work.
///
/// Only stopped Sessions count, so a Session left open (say the app was
/// killed) can't grow the number by itself.
Duration longestStretch(Iterable<Session> sessions) => sessions
    .where((s) => s.stopped)
    .fold(
      Duration.zero,
      (best, s) => s.longestStretch > best ? s.longestStretch : best,
    );

/// One evening the Longest stretch grew, and what it grew to.
typedef StretchRise = ({DateTime evening, Duration longest});

/// How the Longest stretch across [sessions] (all of one kind of Work) has
/// risen over time: one entry per evening it grew, oldest first, the last
/// being the Longest stretch now. Evenings follow [eveningOf].
///
/// Like [longestStretch], only stopped Sessions count, and a Session with no
/// time in it is no rise.
List<StretchRise> longestStretchTrend(Iterable<Session> sessions) {
  final stopped = [
    for (final s in sessions)
      if (s.stopped && s.startedAt != null) s,
  ]..sort((a, b) => a.startedAt!.compareTo(b.startedAt!));
  final rises = <StretchRise>[];
  var best = Duration.zero;
  for (final s in stopped) {
    if (s.longestStretch <= best) continue;
    best = s.longestStretch;
    final evening = eveningOf(s.startedAt!);
    if (rises.lastOrNull?.evening == evening) rises.removeLast();
    rises.add((evening: evening, longest: best));
  }
  return rises;
}

/// Tonight's Aim: the Longest stretch plus one minute.
/// It's rounded up to a whole minute, so the number the user sees ("7
/// minutes") is exactly the one they have to reach.
Duration aimFor(Duration longestStretch) {
  final seconds = (longestStretch + const Duration(minutes: 1)).inSeconds;
  return Duration(minutes: (seconds + 59) ~/ 60);
}

/// Whether [tonight] grew the Longest stretch beyond what [before] reached.
/// A user's first Session counts, as long as it has any time in it.
bool isNewBest(Session tonight, Iterable<Session> before) =>
    tonight.longestStretch > longestStretch(before);
