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
    await store().createSignIn(name, 'token-of-$name', DateTime.now());
    expect(await store().deleteSignIn('token-of-$name'), isTrue);
    expect(await store().deleteSignIn('token-of-$name'), isFalse);
    expect(await store().useSignIn('token-of-$name', DateTime.now()), isNull);
  });

  test('a sign-in in use stays valid', () async {
    final name = freshName();
    final start = DateTime.now();
    await store().createAccount(name, 'hash');
    await store().createSignIn(name, 'token-of-$name', start);
    // Each use restarts the idle time, so three almost-limits in a row pass.
    final almost = signInIdleLimit - const Duration(minutes: 1);
    for (var i = 1; i <= 3; i++) {
      expect(
        await store().useSignIn('token-of-$name', start.add(almost * i)),
        name,
      );
    }
  });

  test('a sign-in unused for the idle limit no longer counts', () async {
    final name = freshName();
    final start = DateTime.now();
    await store().createAccount(name, 'hash');
    await store().createSignIn(name, 'token-of-$name', start);
    expect(
      await store().useSignIn('token-of-$name', start.add(signInIdleLimit)),
      isNull,
    );
  });

  test('an unknown token belongs to nobody', () async {
    expect(await store().useSignIn('no-such-token', DateTime.now()), isNull);
  });
}
