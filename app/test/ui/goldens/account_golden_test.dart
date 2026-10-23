import 'dart:convert';

import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread_core/accounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers.dart';

void main() {
  Future<void> openAccount(
    WidgetTester tester,
    AppDatabase db,
    String lang, {
    bool signedIn = false,
  }) async {
    tester.view
      ..physicalSize = const Size(720, 1560)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final settings = SettingsRepository(db);
    await settings.setLocale(Locale(lang));
    final auth = AuthRepository(
      db,
      MockClient(
        (_) async => http.Response(
          jsonEncode({'token': 'tok', 'username': 'sara'}),
          200,
        ),
      ),
    );
    if (signedIn) {
      await auth.signIn(
        const Credentials(username: 'sara', password: 'longenough'),
      );
    }

    await tester.pumpWidget(DoomreadApp(db: db, auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
  }

  for (final lang in ['en', 'fa']) {
    testApp('Account, signed out, in $lang', (tester, db) async {
      await openAccount(tester, db, lang);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('account_signed_out_$lang.png'),
      );
    });

    testApp('Account, signed in, in $lang', (tester, db) async {
      await openAccount(tester, db, lang, signedIn: true);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('account_signed_in_$lang.png'),
      );
    });
  }
}
