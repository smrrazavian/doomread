/// What the app and the sync server send each other about accounts.
///
/// Both sides check credentials with the same rules, so the app can say
/// what's wrong before a request ever leaves the phone.
library;

/// Why a username or password can't be used for an account.
enum CredentialsProblem { username, password }

/// A username and password, as typed by the user to sign up or sign in.
class Credentials {
  const Credentials({required this.username, required this.password});

  factory Credentials.fromJson(Map<String, Object?> json) => Credentials(
    username: json['username']! as String,
    password: json['password']! as String,
  );

  final String username;
  final String password;

  static final _username = RegExp(r'^[a-z0-9_.]{3,32}$');

  /// The first rule these credentials break, or null if they are fine.
  CredentialsProblem? get problem {
    if (!_username.hasMatch(username)) return CredentialsProblem.username;
    // The upper bound stops a huge password from tying up the password hash.
    if (password.length < 8 || password.length > 256) {
      return CredentialsProblem.password;
    }
    return null;
  }

  Map<String, Object?> toJson() => {'username': username, 'password': password};

  // Never let a password reach a log line through string interpolation.
  @override
  String toString() => 'Credentials($username)';
}

/// A signed-in device: the bearer token the server issued, and whose it is.
class SignIn {
  const SignIn({required this.token, required this.username});

  factory SignIn.fromJson(Map<String, Object?> json) => SignIn(
    token: json['token']! as String,
    username: json['username']! as String,
  );

  final String token;
  final String username;

  Map<String, Object?> toJson() => {'token': token, 'username': username};

  @override
  String toString() => 'SignIn($username)';
}
