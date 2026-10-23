import 'dart:convert';
import 'dart:io';

import 'package:doomread/app.dart';
import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openAccount(WidgetTester tester, MockClient server) async {
    await tester.pumpWidget(
      DoomreadApp(
        settings: SettingsRepository(db),
        auth: AuthRepository(db, server),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
  }

  Future<void> typeCredentials(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'sara');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'correct horse',
    );
  }

  testWidgets('signs up from Settings, then signs out', (tester) async {
    final server = MockClient((request) async {
      if (request.method == 'DELETE') return http.Response('', 204);
      return http.Response(
        jsonEncode({'token': 'tok', 'username': 'sara'}),
        201,
      );
    });
    await openAccount(tester, server);

    await typeCredentials(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as sara'), findsOne);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOne);
    expect(await AuthRepository(db, server).username(), isNull);
  });

  testWidgets('says so kindly when the server is out of reach', (tester) async {
    await openAccount(
      tester,
      MockClient((_) => throw const SocketException('offline')),
    );

    await typeCredentials(tester);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Can't reach the server"), findsOne);
    expect(find.text('Signed in as sara'), findsNothing);
  });

  testWidgets('a wrong password is shown, not a crash', (tester) async {
    await openAccount(
      tester,
      MockClient((_) async => http.Response('{}', 401)),
    );

    await typeCredentials(tester);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Wrong username or password.'), findsOne);
  });
}
