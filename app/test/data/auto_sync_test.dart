import 'dart:async';

import 'package:doomread/data/services/auto_sync.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // testWidgets for its fake clock: timers move only when pumped.
  testWidgets('syncs at start, after nudges settle, on a timer and on resume', (
    tester,
  ) async {
    var runs = 0;
    final nudges = StreamController<void>.broadcast();
    final auto = AutoSync(
      () async => runs++,
      nudges: [nudges.stream],
      every: const Duration(minutes: 10),
    );
    await tester.pump();
    expect(runs, 1);

    // A burst of local changes syncs once, a moment after the last one.
    nudges
      ..add(null)
      ..add(null);
    await tester.pump(const Duration(seconds: 2));
    expect(runs, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(runs, 2);

    await tester.pump(const Duration(minutes: 10));
    expect(runs, 3);

    auto.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(runs, 4);

    auto.dispose();
    await nudges.close();
  });

  testWidgets('runs one at a time, and once more for a nudge meanwhile', (
    tester,
  ) async {
    var runs = 0;
    var gate = Completer<void>();
    final auto = AutoSync(() async {
      runs++;
      await gate.future;
      throw Exception('offline');
    }, nudges: const []);
    await tester.pump();
    expect(runs, 1);

    auto
      ..didChangeAppLifecycleState(AppLifecycleState.resumed)
      ..didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(runs, 1);

    gate.complete();
    gate = Completer<void>()..complete();
    await tester.pump();
    // The failure didn't stop it, and both resumes asked for one more run.
    expect(runs, 2);
    auto.dispose();
  });
}
