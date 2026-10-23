import 'package:doomread/utils/result.dart';
import 'package:flutter/foundation.dart';

/// A user action a view can run and watch: whether it's running and how it
/// ended. From Flutter's architecture guide (Compass sample), trimmed to the
/// one-argument form this app uses so far.
class Command1<T, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  bool running = false;
  Result<T>? result;

  Future<void> execute(A argument) async {
    if (running) return;
    running = true;
    result = null;
    notifyListeners();
    try {
      result = await _action(argument);
    } finally {
      running = false;
      notifyListeners();
    }
  }
}
