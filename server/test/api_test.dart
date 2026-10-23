import 'dart:async';
import 'dart:convert';

import 'package:doomread_core/accounts.dart';
import 'package:doomread_server/server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryAccountStore store;
  late Handler handler;

  setUp(() {
    store = InMemoryAccountStore();
    // Cheap hashing: the real cost would make every test take seconds.
    handler = doomreadServer(store, passwords: const Passwords.cheapForTests());
  });

  Future<Response> send(
    String method,
    String path, {
    Credentials? body,
    String? token,
  }) async => await handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body == null ? null : jsonEncode(body.toJson()),
      headers: {'authorization': ?(token == null ? null : 'Bearer $token')},
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
    final session = Session.fromJson(await json(r));
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
    final first = Session.fromJson(
      await json(await send('POST', '/accounts', body: sara)),
    );
    final r = await send('POST', '/sessions', body: sara);
    expect(r.statusCode, 200);
    final second = Session.fromJson(await json(r));
    expect(second.username, 'sara');
    expect(second.token, isNot(first.token));
  });

  test('a wrong password or unknown username gets 401', () async {
    await send('POST', '/accounts', body: sara);
    for (final wrong in [
      const Credentials(username: 'sara', password: 'wrong horse'),
      const Credentials(username: 'nobody', password: 'correct horse'),
    ]) {
      final r = await send('POST', '/sessions', body: wrong);
      expect(r.statusCode, 401, reason: wrong.username);
    }
  });

  test('signing out ends the session', () async {
    final session = Session.fromJson(
      await json(await send('POST', '/accounts', body: sara)),
    );
    final out = await send('DELETE', '/sessions/current', token: session.token);
    expect(out.statusCode, 204);
    final again = await send(
      'DELETE',
      '/sessions/current',
      token: session.token,
    );
    expect(again.statusCode, 401);
  });

  test('stores neither the password nor the token in the clear', () async {
    final session = Session.fromJson(
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
        await send('POST', '/sessions', body: sara);
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => logged.writeln(line),
      ),
    );
    expect(logged.toString(), contains('/accounts')); // requests are logged
    expect(logged.toString(), isNot(contains(sara.password)));
  });
}
