import 'dart:convert';
import 'dart:io';

import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/accounts.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late AppDatabase db;
  final requests = <http.Request>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    requests.clear();
  });
  tearDown(() => db.close());

  AuthRepository withServer(int status, [Map<String, Object?>? body]) =>
      AuthRepository(
        db,
        MockClient((request) async {
          requests.add(request);
          return http.Response(jsonEncode(body ?? {}), status);
        }),
        server: Uri.parse('http://doomread.test'),
      );

  const sara = Credentials(username: 'sara', password: 'correct horse');
  const session = {'token': 'tok-123', 'username': 'sara'};

  test('is signed out on a fresh install', () async {
    expect(await withServer(200).username(), isNull);
  });

  test('signing up posts the credentials and remembers the session', () async {
    final auth = withServer(201, session);

    final result = await auth.signUp(sara);

    expect(result, isA<Ok<String>>());
    expect(requests.single.method, 'POST');
    expect(requests.single.url.toString(), 'http://doomread.test/accounts');
    expect(jsonDecode(requests.single.body), sara.toJson());
    // A fresh repository on the same database is still signed in.
    expect(await withServer(200).username(), 'sara');
  });

  test('signing in posts to /sign-ins', () async {
    final result = await withServer(200, session).signIn(sara);

    expect((result as Ok<String>).value, 'sara');
    expect(requests.single.url.path, '/sign-ins');
  });

  test('turns server refusals into failures it can explain', () async {
    final cases = {
      409: AuthFailure.usernameTaken,
      401: AuthFailure.wrongCredentials,
      429: AuthFailure.tooManyAttempts,
      400: AuthFailure.rejected,
      500: AuthFailure.unreachable,
    };
    for (final MapEntry(key: status, value: failure) in cases.entries) {
      final result = await withServer(status).signIn(sara);
      expect(
        ((result as Error<String>).error as AuthException).failure,
        failure,
        reason: '$status',
      );
    }
    expect(await withServer(200).username(), isNull);
  });

  test('an unreachable server is a failure, not a crash', () async {
    final auth = AuthRepository(
      db,
      MockClient((_) => throw const SocketException('offline')),
      server: Uri.parse('http://doomread.test'),
    );
    final result = await auth.signIn(sara);
    expect(
      ((result as Error<String>).error as AuthException).failure,
      AuthFailure.unreachable,
    );
  });

  test('checks the credentials before sending anything', () async {
    final result = await withServer(
      201,
      session,
    ).signUp(const Credentials(username: 'sara', password: 'short'));
    expect(
      ((result as Error<String>).error as AuthException).failure,
      AuthFailure.password,
    );
    expect(requests, isEmpty);
  });

  test('signing out ends the session on the server with its token', () async {
    await withServer(201, session).signUp(sara);
    requests.clear();

    await withServer(204).signOut();

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/sign-ins/current');
    expect(requests.single.headers['authorization'], 'Bearer tok-123');
    expect(await withServer(200).username(), isNull);
  });

  test('signing out works offline too', () async {
    await withServer(201, session).signUp(sara);
    final offline = AuthRepository(
      db,
      MockClient((_) => throw const SocketException('offline')),
      server: Uri.parse('http://doomread.test'),
    );

    await offline.signOut();

    expect(await offline.username(), isNull);
  });
}
