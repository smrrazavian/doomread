import 'package:doomread_core/src/session.dart';

/// Watched by default: Instagram and TikTok (both of its packages).
const defaultWatched = {
  'com.instagram.android',
  'com.zhiliaoapp.musically',
  'com.ss.android.ugc.trill',
};

/// Never Watched, whatever the user picks: settings and package installers,
/// so Doomread never stands between the user and turning it off or
/// uninstalling anything.
const neverWatched = {
  'com.android.settings',
  'com.android.packageinstaller',
  'com.google.android.packageinstaller',
  'com.android.vending',
};

/// A screen inside an app that is Watched on its own while that app is the
/// Work app, told apart by the views on it.
class WatchedScreen {
  const WatchedScreen({
    required this.package,
    required this.name,
    required this.anyOf,
  });

  final String package;

  /// What the Urge calls it.
  final String name;

  /// View resource ids; the screen is up when any of them is on it.
  final Set<String> anyOf;

  bool showing(String app, Set<String> views) =>
      app == package && views.any(anyOf.contains);
}

/// The screens Watched inside a Work app. YouTube can hold the Work (a
/// podcast) and Shorts, in one package, so only Shorts is Watched there.
/// Captured from YouTube 21.42; normal videos and the feed have none of
/// these (test/layouts). Data, so it can follow YouTube when it changes.
const watchedScreens = [
  WatchedScreen(
    package: 'com.google.android.youtube',
    name: 'YouTube Shorts',
    anyOf: {
      'com.google.android.youtube:id/reel_recycler',
      'com.google.android.youtube:id/reel_watch_player',
      'com.google.android.youtube:id/reel_player_page_container',
    },
  ),
];

/// The rules data that says which app in front is a Watched app. Native code
/// only reports the app, and for the Work app which of [views] are on
/// screen; it is classified here.
class WatchRules {
  const WatchRules({
    required this.watched,
    this.workApp,
    this.never = neverWatched,
    this.screens = watchedScreens,
  });

  /// Android package names the user picked.
  final Set<String> watched;

  /// The app that holds tonight's Work. Switching to it is never an Urge,
  /// only its [screens] are.
  final String? workApp;

  /// Packages that are never Watched, even when picked.
  final Set<String> never;

  final List<WatchedScreen> screens;

  /// The Watched screen up in [app], given the [views] on screen.
  WatchedScreen? screen(String app, [Set<String> views = const {}]) =>
      screens.where((s) => s.showing(app, views)).firstOrNull;

  bool isWatched(String app, [Set<String> views = const {}]) {
    if (never.contains(app)) return false;
    if (app == workApp) return screen(app, views) != null;
    return watched.contains(app);
  }

  /// The view ids to look for, by package: only the Work app's screens.
  Map<String, Set<String>> get views => {
    for (final s in screens)
      if (s.package == workApp) s.package: {...s.anyOf},
  };
}

/// Whether [session] can raise a new Urge now: a Stretch is running and
/// none is up already. So never on a Pause, a Planned break or after Stop,
/// and not after a Slip, since the user chose the Watched app and is in it.
bool urgeCanRise(Session session) =>
    session.current != null && !session.urgeOpen;

/// Whether [app] coming to the front during [session], with [views] on
/// screen, raises a new Urge.
bool raisesUrge(
  Session session,
  String app,
  WatchRules rules, [
  Set<String> views = const {},
]) => urgeCanRise(session) && rules.isWatched(app, views);

/// Whether [app] coming to the front brings the Urge that's already up back
/// over it: the user went back to the Watched app without answering.
bool bringsUrgeBack(
  Session session,
  String app,
  WatchRules rules, [
  Set<String> views = const {},
]) => session.urgeOpen && rules.isWatched(app, views);
