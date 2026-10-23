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

/// The rules data that says which app in front is a Watched app. Native code
/// only reports the app; it is classified here.
class WatchRules {
  const WatchRules({required this.watched, this.never = neverWatched});

  /// Android package names the user picked.
  final Set<String> watched;

  /// Packages that are never Watched, even when picked.
  final Set<String> never;

  bool isWatched(String app) => watched.contains(app) && !never.contains(app);
}

/// Whether [session] can raise a new Urge now: a Stretch is running and
/// none is up already. So never on a Pause, a Planned break or after Stop,
/// and not after a Slip, since the user chose the Watched app and is in it.
bool urgeCanRise(Session session) =>
    session.current != null && !session.urgeOpen;

/// Whether [app] coming to the front during [session] raises a new Urge.
bool raisesUrge(Session session, String app, WatchRules rules) =>
    urgeCanRise(session) && rules.isWatched(app);

/// Whether [app] coming to the front brings the Urge that's already up back
/// over it: the user went back to the Watched app without answering.
bool bringsUrgeBack(Session session, String app, WatchRules rules) =>
    session.urgeOpen && rules.isWatched(app);
