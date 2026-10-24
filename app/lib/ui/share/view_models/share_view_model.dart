import 'dart:async';

import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/services/share_sheet.dart';
import 'package:doomread/ui/share/poster_extras.dart';
import 'package:doomread/utils/command.dart';
import 'package:doomread/utils/result.dart';
import 'package:flutter/foundation.dart';

/// A drawn poster, and the share sheet's title for it.
typedef Poster = ({Uint8List png, String title});

/// Sharing a drawn card, whichever it is. The file is named by the clock.
class ShareViewModel extends ChangeNotifier {
  ShareViewModel(this._sheet, this._now) {
    share = Command1(_share);
  }

  final ShareSheet _sheet;
  final DateTime Function() _now;

  /// Shares a drawn poster. It ends with where the image was saved on
  /// Linux, or null once Android's share sheet is up.
  late final Command1<String?, Poster> share;

  Future<Result<String?>> _share(Poster poster) async {
    final t = _now();
    String two(int n) => '$n'.padLeft(2, '0');
    final name =
        'doomread-${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}.png';
    return Result.ok(
      await _sheet.sharePng(poster.png, name: name, title: poster.title),
    );
  }
}

/// What the Finish poster says beyond the Finish, and whether the user's
/// Note goes on it.
class FinishShareViewModel extends ChangeNotifier {
  FinishShareViewModel(SessionRepository sessions, {required this.workId})
    : _now = sessions.now {
    _sub = sessions.watchAll().listen((all) {
      _extras = posterExtras(workId, all, _now());
      notifyListeners();
    });
  }

  final String workId;
  final DateTime Function() _now;
  late final StreamSubscription<Object?> _sub;

  PosterExtras get extras => _extras;
  PosterExtras _extras = (urgesLetPass: 0, lastNote: null);

  /// Whether the last Note goes on the poster. On by default: the user sees
  /// it in the preview and can turn it off before anything is shared.
  bool get showNote => _showNote;
  bool _showNote = true;

  set showNote(bool value) {
    _showNote = value;
    notifyListeners();
  }

  /// The Note on the poster right now; null when there's none or it's off.
  String? get note => _showNote ? _extras.lastNote : null;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
