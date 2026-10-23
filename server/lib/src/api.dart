import 'dart:convert';
import 'dart:io';

import 'package:doomread_core/accounts.dart';
import 'package:doomread_server/src/account_store.dart';
import 'package:doomread_server/src/passwords.dart';
import 'package:doomread_server/src/rate_limit.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// The whole HTTP API, request logging included.
///
/// The log shows method, path and status only; bodies (passwords) and
/// headers (tokens) never reach it. [clock] is there for tests.
Handler doomreadServer(
  AccountStore store, {
  Passwords passwords = const Passwords(),
  DateTime Function() clock = DateTime.now,
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
    await store.createSignIn(username, await hashToken(token), clock());
    return _json(status, SignIn(token: token, username: username).toJson());
  }

  /// The hash of the request's bearer token, if it carries one.
  Future<String?> bearerHash(Request request) async {
    final header = request.headers['authorization'] ?? '';
    if (!header.startsWith('Bearer ')) return null;
    return await hashToken(header.substring(7));
  }

  // Sign in and sign up share both limits. The IP one is looser: Iranian
  // mobile carriers put many people behind one address (CGNAT).
  final perIp = RateLimiter(
    limit: attemptsPerIp,
    window: attemptsWindow,
    clock: clock,
  );
  final perUsername = RateLimiter(
    limit: attemptsPerUsername,
    window: attemptsWindow,
    clock: clock,
  );

  /// Reads the credentials, or says why not: 400, or 429 past a limit.
  /// Unknown usernames count like real ones, so a 429 reveals nothing.
  Future<(Credentials?, Response?)> attempt(Request request) async {
    if (_tooMany(perIp.hit(_clientIp(request))) case final r?) return (null, r);
    final c = await readCredentials(request);
    if (c == null) return (null, _error(400, 'bad_request'));
    if (_tooMany(perUsername.hit(c.username)) case final r?) return (null, r);
    return (c, null);
  }

  final router = Router()
    ..get('/health', (Request _) => _json(200, {'status': 'ok'}))
    ..post('/accounts', (Request request) async {
      final (c, refused) = await attempt(request);
      if (c == null) return refused!;
      if (c.problem case final problem?) return _error(400, problem.name);
      final created = await store.createAccount(
        c.username,
        await passwords.hash(c.password),
      );
      if (!created) return _error(409, 'username_taken');
      return await startSignIn(c.username, 201);
    })
    ..post('/sign-ins', (Request request) async {
      final (c, refused) = await attempt(request);
      if (c == null) return refused!;
      if (c.problem != null) return _error(401, 'wrong_credentials');
      final stored = await store.passwordHash(c.username);
      final ok = await passwords.verify(c.password, stored ?? await decoy);
      if (stored == null || !ok) return _error(401, 'wrong_credentials');
      return await startSignIn(c.username, 200);
    })
    ..delete('/sign-ins/current', (Request request) async {
      final hash = await bearerHash(request);
      // An expired sign-in counts as signed out already.
      if (hash == null || await store.useSignIn(hash, clock()) == null) {
        return _error(401, 'not_signed_in');
      }
      await store.deleteSignIn(hash);
      return Response(204);
    });

  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}

const _maxBody = 4096;

/// Sign-in and sign-up attempts allowed per [attemptsWindow], from one IP
/// address and for one username.
const attemptsPerIp = 60;
const attemptsPerUsername = 10;
const attemptsWindow = Duration(minutes: 15);

/// The peer's address. Behind a reverse proxy this is the proxy's, so the
/// limit per IP would throttle everyone together; read the client's from
/// X-Forwarded-For then, and only when the proxy is trusted to set it.
String _clientIp(Request request) =>
    switch (request.context['shelf.io.connection_info']) {
      HttpConnectionInfo(:final remoteAddress) => remoteAddress.address,
      _ => 'unknown',
    };

Response? _tooMany(Duration? retryAfter) => retryAfter == null
    ? null
    : Response(
        429,
        body: jsonEncode({'error': 'too_many_attempts'}),
        headers: {
          'content-type': 'application/json',
          // Whole seconds, rounded up.
          'retry-after': '${(retryAfter.inMicroseconds / 1e6).ceil()}',
        },
      );

Response _json(int status, Map<String, Object?> body) => Response(
  status,
  body: jsonEncode(body),
  headers: {'content-type': 'application/json'},
);

Response _error(int status, String code) => _json(status, {'error': code});
