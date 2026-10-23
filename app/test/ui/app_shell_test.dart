import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(DoomreadApp(settings: SettingsRepository(db)));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Tonight with the four sections in the bottom nav', (
    tester,
  ) async {
    await openApp(tester);

    final nav = find.byType(NavigationBar);
    for (final label in ['Tonight', 'Books', 'Building', 'Friends']) {
      expect(find.descendant(of: nav, matching: find.text(label)), findsOne);
    }
    expect(find.text('Add the book you are reading'), findsOne);
  });

  testWidgets('switching to Persian lays the app out right to left', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فارسی'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); // Android back
    await tester.pumpAndSettle();

    final tonight = find.text('امشب').first;
    expect(Directionality.of(tester.element(tonight)), TextDirection.rtl);
    expect(await SettingsRepository(db).locale(), const Locale('fa'));
  });
}
