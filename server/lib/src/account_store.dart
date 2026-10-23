/// Where accounts and sign-ins live. Postgres in production, memory in tests.
///
/// It only ever sees password hashes and token hashes, never the secrets.
abstract interface class AccountStore {
  /// Creates the account. False if the username is already taken.
  Future<bool> createAccount(String username, String passwordHash);

  /// The stored password hash, or null if there is no such account.
  Future<String?> passwordHash(String username);

  Future<void> createSignIn(String username, String tokenHash);

  /// Ends the sign-in. False if there was no such session.
  Future<bool> deleteSignIn(String tokenHash);
}

class InMemoryAccountStore implements AccountStore {
  final _passwordHashes = <String, String>{};
  final _signIns = <String, String>{}; // token hash -> username

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
  Future<void> createSignIn(String username, String tokenHash) async =>
      _signIns[tokenHash] = username;

  @override
  Future<bool> deleteSignIn(String tokenHash) async =>
      _signIns.remove(tokenHash) != null;

  @override
  // Counts only: even hashes stay out of logs.
  String toString() =>
      'InMemoryAccountStore(${_passwordHashes.length} accounts, '
      '${_signIns.length} sign-ins)';
}
