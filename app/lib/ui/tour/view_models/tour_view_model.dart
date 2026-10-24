import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/domain/use_cases/first_run_use_case.dart';
import 'package:flutter/widgets.dart';

/// The first-run tour, app-wide: whether the intro is due, and which of the
/// one-line hints the guided first Session has still to show.
class TourViewModel extends ChangeNotifier {
  /// [language] is the language the app is in now, saved when the intro
  /// ends if the user never picked one there.
  TourViewModel(this._settings, this._firstRun, {required this.language});

  final SettingsRepository _settings;
  final FirstRunUseCase _firstRun;
  final Locale Function() language;

  /// Whether [load] has finished.
  bool get loaded => _loaded;
  bool _loaded = false;

  /// Whether the intro should show now, instead of the app.
  bool get introDue => _introDue;
  bool _introDue = false;

  Set<Hint> _seen = Hint.values.toSet();
  bool _startSoon = false;

  Future<void> load() async {
    _introDue = await _firstRun();
    _seen = await _settings.hintsSeen();
    _loaded = true;
    notifyListeners();
  }

  /// Whether [hint] is still to be shown.
  bool shows(Hint hint) => _loaded && !_seen.contains(hint);

  /// The user has seen [hint]; it never shows again.
  Future<void> seen(Hint hint) async {
    if (_seen.contains(hint)) return;
    _seen = {..._seen, hint};
    notifyListeners();
    await _settings.setHintsSeen(_seen);
  }

  /// The intro is done, and with [startNow] the first Work was just added,
  /// so Tonight starts its Session straight away.
  Future<void> finishIntro({bool startNow = false}) async {
    _startSoon = startNow;
    _introDue = false;
    notifyListeners();
    await _settings.setIntroSeen();
    // The phone's language, kept from now on, so it can't change under
    // the user later.
    if (await _settings.locale() == null) {
      await _settings.setLocale(language());
    }
  }

  /// Skipping skips the cards and the demo Urge; the one-line hints still
  /// show once each, when their thing first appears.
  Future<void> skipIntro() async {
    await seen(Hint.demoUrge);
    await finishIntro();
  }

  /// Whether the "not yet" screen's ask waits for the demo Urge, which asks
  /// it right after, rather than coming at a Start.
  bool get watchAskWaits => shows(Hint.demoUrge);

  /// Whether Tonight should start the Session now; true once.
  bool takeStart() {
    final start = _startSoon;
    _startSoon = false;
    return start;
  }
}
