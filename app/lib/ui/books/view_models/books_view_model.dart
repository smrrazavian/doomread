import 'dart:async';

import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

class BooksViewModel extends ChangeNotifier {
  BooksViewModel(this._works) {
    _subs = [
      _works.watchAll().listen((w) {
        _all = w;
        notifyListeners();
      }),
      _works.watchCurrent().listen((r) {
        _currentId = r?.work.id;
        notifyListeners();
      }),
    ];
  }

  final WorkRepository _works;
  late final List<StreamSubscription<Object?>> _subs;

  List<Work> get works => _all;
  List<Work> _all = const [];

  String? get currentId => _currentId;
  String? _currentId;

  Future<void> makeCurrent(String id) => _works.setCurrent(id);

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
