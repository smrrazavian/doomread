/// What the user did during a Session, as stored in the journal.
enum SessionEventKind { start, pause, resume, stop }

/// One timestamped entry in a Session's journal. Entries are only ever
/// appended; everything else is derived from them by [Session.fromEvents].
class SessionEvent {
  const SessionEvent(this.kind, this.at);

  final SessionEventKind kind;
  final DateTime at;
}

/// What ended a Stretch.
// ponytail: Slips and the Planned break also end a Stretch; they arrive with
// Urges (#6) and Planned breaks (#5).
enum StretchEnd { pause, stop }

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
    DateTime? runningSince;
    var stopped = false;
    final stretches = <Stretch>[];
    void close(DateTime at, StretchEnd by) {
      if (runningSince == null) return;
      stretches.add(Stretch(runningSince!, at, by));
      runningSince = null;
    }

    for (final (_, e) in indexed) {
      if (stopped) break;
      switch (e.kind) {
        case SessionEventKind.start:
          if (startedAt != null) continue;
          startedAt = e.at;
          runningSince = e.at;
        case _ when startedAt == null:
          continue;
        case SessionEventKind.pause:
          close(e.at, StretchEnd.pause);
        case SessionEventKind.resume:
          runningSince ??= e.at;
        case SessionEventKind.stop:
          close(e.at, StretchEnd.stop);
          stopped = true;
      }
    }
    if (runningSince != null) stretches.add(Stretch(runningSince!, now, null));
    return Session._(startedAt, stretches, stopped: stopped);
  }

  Session._(this.startedAt, List<Stretch> stretches, {required this.stopped})
    : stretches = List.unmodifiable(stretches);

  /// When the Session started; null if the journal has no Start.
  final DateTime? startedAt;

  /// In order, the last one possibly still running.
  final List<Stretch> stretches;

  final bool stopped;

  /// Started, not stopped, and no Stretch running.
  bool get paused =>
      startedAt != null && !stopped && (stretches.lastOrNull?.endedBy != null);

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
