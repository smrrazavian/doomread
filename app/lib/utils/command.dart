import 'package:doomread/utils/result.dart';
import 'package:flutter/foundation.dart';

/// An action a view can run and watch: whether it is running, and how it
/// ended. A second call while one is running is ignored.
///
/// The shape of the official architecture guide's Command.
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  Result<T>? _result;

  bool get running => _running;
  bool get error => _result is Error;
  bool get completed => _result is Ok;
  Result<T>? get result => _result;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> _execute(Future<Result<T>> Function() action) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await action();
    } on Exception catch (e) {
      // A failure the action didn't expect (say, the database) is still shown,
      // not thrown out of a button handler.
      _result = Result.error(e);
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}

class Command0<T> extends Command<T> {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  Future<void> execute() => _execute(_action);
}

class Command1<T, A> extends Command<T> {
  Command1(this._action);

  final Future<Result<T>> Function(A) _action;

  Future<void> execute(A argument) => _execute(() => _action(argument));
}
