import 'dart:math';

import 'package:doomread_server/server.dart';
import 'package:test/test.dart';

/// What every AccountStore adapter must do. Usernames are unique per run,
/// so the Postgres adapter can share a database with other runs.
void accountStoreContract(AccountStore Function() store) {
  final run = Random().nextInt(1 << 32).toRadixString(36);
  var n = 0;
  String freshName() => 'u${run}_${n++}';

  test('creates an account and returns its password hash', () async {
    final name = freshName();
    expect(await store().createAccount(name, 'hash-1'), isTrue);
    expect(await store().passwordHash(name), 'hash-1');
  });

  test('refuses a second account with the same username', () async {
    final name = freshName();
    await store().createAccount(name, 'hash-1');
    expect(await store().createAccount(name, 'hash-2'), isFalse);
    expect(await store().passwordHash(name), 'hash-1');
  });

  test('has no password hash for an unknown username', () async {
    expect(await store().passwordHash(freshName()), isNull);
  });

  test('deletes a session once', () async {
    final name = freshName();
    await store().createAccount(name, 'hash');
    await store().createSession(name, 'token-of-$name');
    expect(await store().deleteSession('token-of-$name'), isTrue);
    expect(await store().deleteSession('token-of-$name'), isFalse);
  });
}
