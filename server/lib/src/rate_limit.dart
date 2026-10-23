/// Counts attempts per key in fixed windows, in memory.
///
/// Its ceiling: the counts live in this process only, so they hold for a
/// single server instance and reset on restart. Run several, and they
/// need a shared store (Postgres or Redis) instead.
class RateLimiter {
  RateLimiter({
    required this.limit,
    required this.window,
    required this._clock,
  });

  final int limit;
  final Duration window;
  final DateTime Function() _clock;

  final _windows = <String, ({DateTime start, int count})>{};
  DateTime? _lastSweep;

  /// Counts one attempt for [key]. Null if it is allowed, otherwise how
  /// long until the key may try again.
  Duration? hit(String key) {
    final now = _clock();
    _sweep(now);
    final current = _windows[key];
    if (current == null || now.difference(current.start) >= window) {
      _windows[key] = (start: now, count: 1);
      return null;
    }
    if (current.count >= limit) {
      return current.start.add(window).difference(now);
    }
    _windows[key] = (start: current.start, count: current.count + 1);
    return null;
  }

  /// Forgets finished windows once per window, so memory follows the
  /// keys seen recently, not every key ever seen.
  void _sweep(DateTime now) {
    if (_lastSweep case final last? when now.difference(last) < window) {
      return;
    }
    _lastSweep = now;
    _windows.removeWhere((_, w) => now.difference(w.start) >= window);
  }
}
