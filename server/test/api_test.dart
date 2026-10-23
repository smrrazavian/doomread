import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doomread_core/accounts.dart';
import 'package:doomread_server/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryAccountStore store;
  late Handler handler;
  late DateTime now;

  setUp(() {
    store = InMemoryAccountStore();
    now = DateTime.utc(2026, 10, 22, 21);
    handler = doomreadServer(
      store,
      // Cheap hashing: the real cost would make every test take seconds.
      passwords: const Passwords.cheapForTests(),
      clock: () => now,
    );
  });

  Future<Response> send(
    String method,
    String path, {
    Credentials? body,
    String? token,
    String ip = '10.0.0.1',
  }) async => await handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body == null ? null : jsonEncode(body.toJson()),
      headers: {'authorization': ?(token == null ? null : 'Bearer $token')},
      // What shelf_io puts there for a real connection.
      context: {'shelf.io.connection_info': _Peer(ip)},
    ),
  );

  Future<Map<String, Object?>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, Object?>;

  const sara = Credentials(username: 'sara', password: 'correct horse');

  test('answers the health check', () async {
    final r = await send('GET', '/health');
    expect(r.statusCode, 200);
    expect(await json(r), {'status': 'ok'});
  });

  test('signing up creates the account and signs the device in', () async {
    final r = await send('POST', '/accounts', body: sara);
    expect(r.statusCode, 201);
    final session = SignIn.fromJson(await json(r));
    expect(session.username, 'sara');
    expect(session.token, hasLength(greaterThanOrEqualTo(40)));
  });

  test('a taken username is refused', () async {
    await send('POST', '/accounts', body: sara);
    final r = await send(
      'POST',
      '/accounts',
      body: const Credentials(username: 'sara', password: 'another one'),
    );
    expect(r.statusCode, 409);
    expect(await json(r), {'error': 'username_taken'});
  });

  test('credentials that break the shared rules are refused', () async {
    final r = await send(
      'POST',
      '/accounts',
      body: const Credentials(username: 'sara', password: 'short'),
    );
    expect(r.statusCode, 400);
    expect(await json(r), {'error': 'password'});
  });

  test('signing in with the right password starts a new session', () async {
    final first = SignIn.fromJson(
      await json(await send('POST', '/accounts', body: sara)),
    );
    final r = await send('POST', '/sign-ins', body: sara);
    expect(r.statusCode, 200);
    final second = SignIn.fromJson(await json(r));
    expect(second.username, 'sara');
    expect(second.token, isNot(first.token));
  });

  test('a wrong password or unknown username gets 401', () async {
    await send('POST', '/accounts', body: sara);
    for (final wrong in [
      const Credentials(username: 'sara', password: 'wrong horse'),
      const Credentials(username: 'nobody', password: 'correct horse'),
    ]) {
      final r = await send('POST', '/sign-ins', body: wrong);
      expect(r.statusCode, 401, reason: wrong.username);
    }
  });

  test('an oversized body is refused before it is read or hashed', () async {
    final huge = Credentials(username: 'sara', password: 'x' * 100000);
    final r = await send('POST', '/sign-ins', body: huge);
    expect(r.statusCode, 400);
  });

  test('signing out ends the sign-in', () async {
    final session = SignIn.fromJson(
      await json(await send('POST', '/accounts', body: sara)),
    );
    final out = await send('DELETE', '/sign-ins/current', token: session.token);
    expect(out.statusCode, 204);
    final again = await send(
      'DELETE',
      '/sign-ins/current',
      token: session.token,
    );
    expect(again.statusCode, 401);
  });

  test('a sign-in left unused for the idle limit has expired', () async {
    final session = SignIn.fromJson(
      await json(await send('POST', '/accounts', body: sara)),
    );
    now = now.add(signInIdleLimit);
    final out = await send('DELETE', '/sign-ins/current', token: session.token);
    expect(out.statusCode, 401);
  });

  test('stores neither the password nor the token in the clear', () async {
    final session = SignIn.fromJson(
      await json(await send('POST', '/accounts', body: sara)),
    );
    final stored = store.toString();
    expect(stored, isNot(contains(sara.password)));
    expect(stored, isNot(contains(session.token)));
  });

  test('never logs credentials or tokens', () async {
    final logged = StringBuffer();
    await runZoned(
      () async {
        await send('POST', '/accounts', body: sara);
        await send('POST', '/sign-ins', body: sara);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => logged.writeln(line),
      ),
    );
    expect(logged.toString(), contains('/accounts')); // requests are logged
    expect(logged.toString(), isNot(contains(sara.password)));
  });

  group('too many attempts', () {
    const wrong = Credentials(username: 'sara', password: 'wrong horse');

    test('on one username get 429, from any address', () async {
      for (var i = 0; i < attemptsPerUsername; i++) {
        final r = await send('POST', '/sign-ins', body: wrong, ip: '10.0.0.$i');
        expect(r.statusCode, 401);
      }
      final r = await send('POST', '/sign-ins', body: sara, ip: '10.9.9.9');
      expect(r.statusCode, 429);
      expect(r.headers['retry-after'], '${attemptsWindow.inSeconds}');
      expect(await json(r), {'error': 'too_many_attempts'});
    });

    test('from one address get 429, whatever the username', () async {
      for (var i = 0; i < attemptsPerIp; i++) {
        final r = await send(
          'POST',
          '/sign-ins',
          body: Credentials(username: 'user$i', password: 'wrong horse'),
        );
        expect(r.statusCode, 401);
      }
      final r = await send('POST', '/accounts', body: sara);
      expect(r.statusCode, 429);
      // Another address still gets through.
      final other = await send('POST', '/accounts', body: sara, ip: '10.1.1.1');
      expect(other.statusCode, 201);
    });

    test('are forgiven once the window has passed', () async {
      for (var i = 0; i < attemptsPerUsername; i++) {
        await send('POST', '/sign-ins', body: wrong);
      }
      now = now.add(attemptsWindow - const Duration(seconds: 90));
      final early = await send('POST', '/sign-ins', body: wrong);
      expect(early.headers['retry-after'], '90');

      now = now.add(const Duration(seconds: 90));
      final r = await send('POST', '/sign-ins', body: wrong);
      expect(r.statusCode, 401);
    });
  });
}

class _Peer implements HttpConnectionInfo {
  _Peer(String ip) : remoteAddress = InternetAddress(ip);

  @override
  final InternetAddress remoteAddress;
  @override
  int get remotePort => 40000;
  @override
  int get localPort => 8080;
}
