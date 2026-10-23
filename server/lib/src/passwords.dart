import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Hashes passwords with Argon2id and checks them against stored hashes.
///
/// A stored hash carries its own cost, so raising the cost later doesn't
/// lock anyone out: `argon2id$m=19456,t=2,p=1$<salt>$<hash>`.
class Passwords {
  /// OWASP's minimum Argon2id settings: 19 MiB, 2 passes, 1 lane.
  const Passwords({this.memory = 19456, this.iterations = 2});

  /// Fast and weak, for tests only.
  const Passwords.cheapForTests() : this(memory: 8, iterations: 1);

  /// In KiB.
  final int memory;
  final int iterations;

  Future<String> hash(String password) async {
    final salt = _randomBytes(16);
    final digest = await _derive(password, salt, memory, iterations);
    return 'argon2id\$m=$memory,t=$iterations,p=1'
        '\$${base64.encode(salt)}\$${base64.encode(digest)}';
  }

  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'argon2id') return false;
    final params = {
      for (final p in parts[1].split(','))
        p.split('=')[0]: int.parse(p.split('=')[1]),
    };
    final digest = await _derive(
      password,
      base64.decode(parts[2]),
      params['m']!,
      params['t']!,
    );
    return constantTimeEquals(digest, base64.decode(parts[3]));
  }

  static Future<List<int>> _derive(
    String password,
    List<int> salt,
    int memory,
    int iterations,
  ) async {
    final key = await Argon2id(
      parallelism: 1,
      memory: memory,
      iterations: iterations,
      hashLength: 32,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
    return await key.extractBytes();
  }
}

final _random = Random.secure();

List<int> _randomBytes(int n) => List.generate(n, (_) => _random.nextInt(256));

/// A new bearer token: 32 random bytes, URL-safe.
String newToken() => base64Url.encode(_randomBytes(32)).replaceAll('=', '');

/// What gets stored for a token, so a leaked database can't sign anyone in.
Future<String> hashToken(String token) async {
  final digest = await Sha256().hash(utf8.encode(token));
  return base64.encode(digest.bytes);
}

/// Compares without stopping at the first difference, so timing leaks nothing.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
