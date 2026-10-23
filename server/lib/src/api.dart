import 'dart:convert';

import 'package:doomread_core/accounts.dart';
import 'package:doomread_server/src/account_store.dart';
import 'package:doomread_server/src/passwords.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// The whole HTTP API, request logging included.
///
/// The log shows method, path and status only; bodies (passwords) and
/// headers (tokens) never reach it.
Handler doomreadServer(
  AccountStore store, {
  Passwords passwords = const Passwords(),
}) {
  // Checked when the username is unknown, so a miss takes as long as a hit
  // and response times don't reveal which usernames exist.
  final decoy = passwords.hash('not a real password');

  Future<Credentials?> readCredentials(Request request) async {
    // Credentials are tiny; stop reading a larger body instead of buffering it.
    final bytes = <int>[];
    await for (final chunk in request.read()) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBody) return null;
    }
    try {
      final body = jsonDecode(utf8.decode(bytes));
      return Credentials.fromJson(body as Map<String, Object?>);
    } on Object {
      return null;
    }
  }

  Future<Response> startSignIn(String username, int status) async {
    final token = newToken();
    await store.createSignIn(username, await hashToken(token));
    return _json(status, SignIn(token: token, username: username).toJson());
  }

  // ponytail: sign-ins never expire; add expiry and a last-used time
  // before tokens can outlive a lost phone.
  // ponytail: no rate limiting on sign in; add it (per IP and per username)
  // before the server is open to the public internet.
  final router = Router()
    ..get('/health', (Request _) => _json(200, {'status': 'ok'}))
    ..post('/accounts', (Request request) async {
      final c = await readCredentials(request);
      if (c == null) return _error(400, 'bad_request');
      if (c.problem case final problem?) return _error(400, problem.name);
      final created = await store.createAccount(
        c.username,
        await passwords.hash(c.password),
      );
      if (!created) return _error(409, 'username_taken');
      return await startSignIn(c.username, 201);
    })
    ..post('/sign-ins', (Request request) async {
      final c = await readCredentials(request);
      if (c == null) return _error(400, 'bad_request');
      if (c.problem != null) return _error(401, 'wrong_credentials');
      final stored = await store.passwordHash(c.username);
      final ok = await passwords.verify(c.password, stored ?? await decoy);
      if (stored == null || !ok) return _error(401, 'wrong_credentials');
      return await startSignIn(c.username, 200);
    })
    ..delete('/sign-ins/current', (Request request) async {
      final header = request.headers['authorization'] ?? '';
      if (!header.startsWith('Bearer ')) return _error(401, 'not_signed_in');
      final deleted = await store.deleteSignIn(
        await hashToken(header.substring(7)),
      );
      return deleted ? Response(204) : _error(401, 'not_signed_in');
    });

  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

const _maxBody = 4096;

Response _json(int status, Map<String, Object?> body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

Response _error(int status, String code) => _json(status, {'error': code});
