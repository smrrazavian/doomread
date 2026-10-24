import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/foundation.dart';

/// One saved Session, for its receipt.
class ReceiptViewModel extends ChangeNotifier {
  ReceiptViewModel(SessionRepository sessions, this.id) : _now = sessions.now {
    _sub = sessions.watchAll().listen((all) {
      _record = all.where((r) => r.id == id).firstOrNull;
      _session = _record?.at(_now());
      notifyListeners();
    });
  }

  final String id;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _sub;

  /// Null until the journal has loaded.
  SessionRecord? get record => _record;
  SessionRecord? _record;

  /// The Session, measured when it loaded.
  Session? get session => _session;
  Session? _session;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
