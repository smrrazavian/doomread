import 'package:doomread/ui/core/road_view.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final work = Work(
    id: 'w',
    title: 'The Remains of the Day',
    author: 'Kazuo Ishiguro',
    totalPages: 200,
    checkpoints: const [50, 150],
  );

  Future<void> pumpRoad(WidgetTester tester, int position) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: RoadView(road: Road(work, position: position)),
        ),
      ),
    ),
  );

  /// Where "you are here" is, from the start of the Road.
  double dot(WidgetTester tester) => tester
      .getCenter(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
      )
      .dx;

  testWidgets('a new Position slides the dot there', (tester) async {
    await pumpRoad(tester, 20);
    final from = dot(tester);
    await pumpRoad(tester, 160);
    await tester.pump(const Duration(milliseconds: 350));
    final between = dot(tester);
    await tester.pumpAndSettle();
    final to = dot(tester);
    expect(to - from, closeTo(140, 0.01));
    expect(between, greaterThan(from));
    expect(between, lessThan(to));
  });

  testWidgets('with reduced motion, the dot jumps', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpRoad(tester, 20);
    final from = dot(tester);
    await pumpRoad(tester, 160);
    await tester.pump();
    expect(dot(tester) - from, closeTo(140, 0.01));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
