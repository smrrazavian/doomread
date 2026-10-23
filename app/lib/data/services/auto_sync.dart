import 'dart:async';

import 'package:flutter/widgets.dart';

/// Runs a sync in the background whenever one might help, and never makes
/// the app wait for it: at start, a moment after any of `triggers` fires (a
/// local change, a sign in), when the app comes back to the front, and
/// every `every` while it is open.
///
/// There's no connectivity check: a sync while offline just fails quickly
/// or times out, and the next one tries again. One runs at a time; a
/// trigger during a run asks for one more run after it.
class AutoSync with WidgetsBindingObserver {
  AutoSync(
    this._sync, {
    required Iterable<Stream<void>> triggers,
    Duration every = const Duration(minutes: 5),
    this.settle = const Duration(seconds: 3),
  }) {
    WidgetsBinding.instance.addObserver(this);
    _triggers = [
      for (final t in triggers)
        t.listen((_) {
          _settling?.cancel();
          _settling = Timer(settle, _run);
        }),
    ];
    _timer = Timer.periodic(every, (_) => _run());
    _run();
  }

  final Future<Object?> Function() _sync;

  /// How long after a trigger to wait for more, so a burst syncs once.
  final Duration settle;

  late final List<StreamSubscription<void>> _triggers;
  late final Timer _timer;
  Timer? _settling;
  bool _running = false;
  bool _again = false;
  bool _disposed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run();
  }

  void _run() {
    if (_disposed) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    unawaited(() async {
      do {
        _again = false;
        try {
          await _sync();
        } on Object {
          // A sync reports its own failures; anything else just waits for
          // the next run too.
        }
      } while (_again && !_disposed);
      _running = false;
    }());
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    for (final t in _triggers) {
      unawaited(t.cancel());
    }
    _timer.cancel();
    _settling?.cancel();
  }
}
