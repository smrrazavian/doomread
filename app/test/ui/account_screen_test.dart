import 'dart:convert';
import 'dart:io';

import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> openAccount(
    WidgetTester tester,
    AppDatabase db,
    MockClient server,
  ) async {
    await skipTour(db);
    await tester.pumpWidget(
      DoomreadApp(db: db, auth: AuthRepository(db, server)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.account));
    await tester.pumpAndSettle();
  }

  Future<void> typeCredentials(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'sara');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'correct horse',
    );
  }

  testApp('signs up from Settings, then signs out', (tester, db) async {
    final server = MockClient((request) async {
      if (request.method == 'DELETE') return http.Response('', 204);
      return http.Response(
        jsonEncode({'token': 'tok', 'username': 'sara'}),
        201,
      );
    });
    await openAccount(tester, db, server);

    await typeCredentials(tester);
    await tester.tap(find.text(en.accountSignUp));
    await tester.pumpAndSettle();
    expect(find.text(en.accountSignedInAs('sara')), findsOne);

    await tester.tap(find.text(en.accountSignOut));
    await tester.pumpAndSettle();
    expect(find.text(en.accountSignIn), findsOne);
    expect(await AuthRepository(db, server).username(), isNull);
  });

  testApp('says so kindly when the server is out of reach', (tester, db) async {
    await openAccount(
      tester,
      db,
      MockClient((_) => throw const SocketException('offline')),
    );

    await typeCredentials(tester);
    await tester.tap(find.text(en.accountSignIn));
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach the server"), findsOne);
    expect(find.text(en.accountSignedInAs('sara')), findsNothing);
  });

  testApp('a wrong password is shown, not a crash', (tester, db) async {
    await openAccount(
      tester,
      db,
      MockClient((_) async => http.Response('{}', 401)),
    );

    await typeCredentials(tester);
    await tester.tap(find.text(en.accountSignIn));
    await tester.pumpAndSettle();

    expect(find.text(en.accountErrorWrong), findsOne);
  });

  testApp('too many tries asks for a few minutes', (tester, db) async {
    await openAccount(
      tester,
      db,
      MockClient((_) async => http.Response('{}', 429)),
    );

    await typeCredentials(tester);
    await tester.tap(find.text(en.accountSignIn));
    await tester.pumpAndSettle();

    expect(find.text(en.accountErrorTooMany), findsOne);
  });
}
