import 'package:doomread/app.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget test of the whole app on a fresh in-memory database.
///
/// drift cancels a stream query on a zero-length timer after its last
/// listener leaves, so the app is unmounted and that timer flushed before the
/// test ends; otherwise Flutter reports a pending timer and close() hangs.
void testApp(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body,
) {
  testWidgets(description, (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await body(tester, db);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}

/// Starts the app on [db] and waits for it to settle.
Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(DoomreadApp(db: db));
  await tester.pumpAndSettle();
}
