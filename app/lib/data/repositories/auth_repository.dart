import 'dart:convert';

import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/accounts.dart';
import 'package:http/http.dart' as http;

/// The sync server. Pick another with
/// `--dart-define=DOOMREAD_SERVER=http://192.168.1.20:8080`
/// (a phone can't reach the laptop's localhost).
// ponytail: release builds have no HTTPS server address yet; set one with
// --dart-define before shipping (ticket #17).
final Uri defaultServer = Uri.parse(
  const String.fromEnvironment(
    'DOOMREAD_SERVER',
    defaultValue: 'http://localhost:8080',
  ),
);

/// Why signing up or in didn't work.
enum AuthFailure {
  /// The username breaks the rules in core; nothing was sent.
  username,

  /// The password breaks the rules in core; nothing was sent.
  password,
  usernameTaken,
  wrongCredentials,

  /// The server refused the request for another reason.
  rejected,

  /// No answer, or a broken one: offline, or the server is down.
  unreachable,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException(${failure.name})';
}

/// The account this device is signed in to, if any.
///
/// Being signed out is a normal state: everything else in the app works
/// without an account, and nothing here runs until the user asks.
class AuthRepository {
  AuthRepository(this._db, this._client, {Uri? server})
    : _server = server ?? defaultServer;

  final AppDatabase _db;
  final http.Client _client;

  /// Blackholed connections (common during outages in Iran) never error on
  /// their own, so give up and say "can't reach the server" instead.
  static const _timeout = Duration(seconds: 12);
  final Uri _server;

  // ponytail: the sign-in token sits in the app's own SQLite file, unencrypted.
  // Move it to the platform keystore once sync gives it something to protect.
  static const _tokenKey = 'session.token';
  static const _usernameKey = 'session.username';

  /// Who is signed in, or null when signed out.
  Future<String?> username() => _read(_usernameKey);

  /// Creates an account and signs this device in to it. Returns the username.
  Future<Result<String>> signUp(Credentials credentials) =>
      _startSignIn('accounts', credentials);

  /// Signs this device in to an existing account. Returns the username.
  Future<Result<String>> signIn(Credentials credentials) =>
      _startSignIn('sign-ins', credentials);

  /// Forgets the session on this device, and on the server when it can be
  /// reached. Always succeeds, even offline.
  Future<void> signOut() async {
    final token = await _read(_tokenKey);
    await (_db.delete(
      _db.settings,
    )..where((s) => s.key.isIn([_tokenKey, _usernameKey]))).go();
    if (token == null) return;
    try {
      await _client
          .delete(
            _server.resolve('sign-ins/current'),
            headers: {'authorization': 'Bearer $token'},
          )
          .timeout(_timeout);
    } on Exception {
      // ponytail: an offline sign-out leaves the sign-in alive on the server
      // until it expires there, and sign-ins don't expire yet.
    }
  }

  Future<Result<String>> _startSignIn(
    String path,
    Credentials credentials,
  ) async {
    switch (credentials.problem) {
      case CredentialsProblem.username:
        return const Result.error(AuthException(AuthFailure.username));
      case CredentialsProblem.password:
        return const Result.error(AuthException(AuthFailure.password));
      case null:
    }
    final SignIn session;
    try {
      final response = await _client
          .post(
            _server.resolve(path),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(credentials.toJson()),
          )
          .timeout(_timeout);
      final failure = switch (response.statusCode) {
        200 || 201 => null,
        409 => AuthFailure.usernameTaken,
        401 => AuthFailure.wrongCredentials,
        >= 400 && < 500 => AuthFailure.rejected,
        _ => AuthFailure.unreachable,
      };
      if (failure != null) return Result.error(AuthException(failure));
      session = SignIn.fromJson(
        jsonDecode(response.body) as Map<String, Object?>,
      );
    } on Exception {
      return const Result.error(AuthException(AuthFailure.unreachable));
    }
    await _db.batch(
      (b) => b.insertAllOnConflictUpdate(_db.settings, [
        SettingsCompanion.insert(key: _tokenKey, value: session.token),
        SettingsCompanion.insert(key: _usernameKey, value: session.username),
      ]),
    );
    return Result.ok(session.username);
  }

  Future<String?> _read(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;
}
