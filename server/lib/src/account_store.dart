/// How long a sign-in lasts without being used. Each use restarts it, so a
/// phone that syncs stays signed in, and a lost one stops working in time.
const signInIdleLimit = Duration(days: 90);

/// Where accounts and sign-ins live. Postgres in production, memory in tests.
///
/// It only ever sees password hashes and token hashes, never the secrets.
/// Times come from the caller, so tests can move the clock.
abstract interface class AccountStore {
  /// Creates the account. False if the username is already taken.
  Future<bool> createAccount(String username, String passwordHash);

  /// The stored password hash, or null if there is no such account.
  Future<String?> passwordHash(String username);

  Future<void> createSignIn(String username, String tokenHash, DateTime now);

  /// The username a sign-in belongs to, and marks it used at [now]. Null if
  /// there is no such sign-in or it went unused for [signInIdleLimit].
  Future<String?> useSignIn(String tokenHash, DateTime now);

  /// Ends the sign-in. False if there was no such session.
  Future<bool> deleteSignIn(String tokenHash);
}

class InMemoryAccountStore implements AccountStore {
  final _passwordHashes = <String, String>{};
  final _signIns = <String, ({String username, DateTime lastUsed})>{};

  @override
  Future<bool> createAccount(String username, String passwordHash) async {
    if (_passwordHashes.containsKey(username)) return false;
    _passwordHashes[username] = passwordHash;
    return true;
  }

  @override
  Future<String?> passwordHash(String username) async =>
      _passwordHashes[username];

  @override
  Future<void> createSignIn(
    String username,
    String tokenHash,
    DateTime now,
  ) async => _signIns[tokenHash] = (username: username, lastUsed: now);

  @override
  Future<String?> useSignIn(String tokenHash, DateTime now) async {
    final signIn = _signIns[tokenHash];
    if (signIn == null ||
        !signIn.lastUsed.isAfter(now.subtract(signInIdleLimit))) {
      return null;
    }
    _signIns[tokenHash] = (username: signIn.username, lastUsed: now);
    return signIn.username;
  }

  @override
  Future<bool> deleteSignIn(String tokenHash) async =>
      _signIns.remove(tokenHash) != null;

  @override
  // Counts only: even hashes stay out of logs.
  String toString() =>
      'InMemoryAccountStore(${_passwordHashes.length} accounts, '
      '${_signIns.length} sign-ins)';
}
