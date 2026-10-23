import 'dart:async';

import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/accounts.dart';
import 'package:flutter/foundation.dart';

class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._auth) {
    load = Command0(_load);
    unawaited(load.execute());
    // Each clears the other's result, so only the latest failure shows.
    signIn = Command1((c) {
      signUp.clearResult();
      return _auth.signIn(c);
    });
    signUp = Command1((c) {
      signIn.clearResult();
      return _auth.signUp(c);
    });
    signIn.addListener(_onSession(signIn));
    signUp.addListener(_onSession(signUp));
    signOut = Command0(_signOut);
  }

  final AuthRepository _auth;

  late final Command0<void> load;
  late final Command1<String, Credentials> signIn;
  late final Command1<String, Credentials> signUp;
  late final Command0<void> signOut;

  /// Who is signed in on this device, or null when signed out.
  String? get username => _username;
  String? _username;

  /// Why the last sign in or sign up failed, if it did.
  AuthFailure? get failure => switch (signIn.result ?? signUp.result) {
    Error(error: AuthException(:final failure)) => failure,
    Error() => AuthFailure.unreachable,
    _ => null,
  };

  VoidCallback _onSession(Command<String> command) => () {
    if (command.result case Ok(:final value) when _username != value) {
      _username = value;
      notifyListeners();
    }
  };

  Future<Result<void>> _load() async {
    _username = await _auth.username();
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> _signOut() async {
    await _auth.signOut();
    _username = null;
    signIn.clearResult();
    signUp.clearResult();
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  void dispose() {
    for (final c in [load, signIn, signUp, signOut]) {
      c.dispose();
    }
    super.dispose();
  }
}
