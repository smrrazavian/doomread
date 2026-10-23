import 'package:doomread_core/accounts.dart';
import 'package:test/test.dart';

void main() {
  test('credentials and sign-ins survive a trip through JSON', () {
    const credentials = Credentials(username: 'sara', password: 'longenough');
    final back = Credentials.fromJson(credentials.toJson());
    expect((back.username, back.password), ('sara', 'longenough'));

    const session = SignIn(token: 'abc', username: 'sara');
    final s = SignIn.fromJson(session.toJson());
    expect((s.token, s.username), ('abc', 'sara'));
  });

  test('accepts a plain username and an 8-character password', () {
    expect(
      const Credentials(username: 'sara_92', password: '12345678').problem,
      isNull,
    );
  });

  test('refuses short, long or oddly shaped usernames', () {
    for (final name in ['sa', 'a' * 33, 'Sara', 'sa ra', 'سارا']) {
      expect(
        Credentials(username: name, password: '12345678').problem,
        CredentialsProblem.username,
        reason: name,
      );
    }
  });

  test('refuses a password shorter than 8 characters', () {
    expect(
      const Credentials(username: 'sara', password: '1234567').problem,
      CredentialsProblem.password,
    );
  });
}
