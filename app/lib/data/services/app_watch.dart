import 'dart:io';

import 'package:flutter/services.dart';

/// An app the user can launch, as the picker of Watched apps lists it.
typedef LaunchableApp = ({String package, String label});

/// How Doomread hears which app is in front.
enum WatchMethod { accessibility, usageAccess }

/// What the user has granted, in the system settings, for watching apps.
typedef WatchGrants = ({bool accessibility, bool usageAccess, bool overlay});

/// Accessibility when it's on: it's instant and can tell Shorts apart.
/// Otherwise usage access, polled, with display over other apps so Doomread
/// can come to the front (ADR 0016). Null when neither is granted.
WatchMethod? pickWatchMethod(WatchGrants g) => g.accessibility
    ? WatchMethod.accessibility
    : g.usageAccess && g.overlay
    ? WatchMethod.usageAccess
    : null;

/// Which app is in front, from a small native edge on Android with two
/// sources behind it: an AccessibilityService that only reports the app
/// (ADR 0014), or usage access, polled (ADR 0016). Whether it's Watched is
/// decided in core. Everywhere else every call does nothing.
class AppWatch {
  AppWatch() {
    if (available) _channel.setMethodCallHandler(_fromNative);
  }

  static const _channel = MethodChannel('doomread/watch');

  /// Whether this platform can watch apps at all.
  bool get available => Platform.isAndroid;

  /// Called with the app that just came to the front, while [setWatching]
  /// is on, and which of the views asked for are on its screen.
  void Function(String package, String label, Set<String> views)? onForeground;

  Future<Object?> _fromNative(MethodCall call) async {
    if (call.method == 'foreground') {
      final args = call.arguments! as Map<Object?, Object?>;
      onForeground?.call(args['package']! as String, args['label']! as String, {
        ...(args['views'] as List<Object?>? ?? const []).cast<String>(),
      });
    }
    return null;
  }

  /// What the user has granted; nothing where apps can't be watched.
  Future<WatchGrants> grants() async {
    final g = available
        ? await _channel.invokeMapMethod<String, bool>('grants')
        : null;
    return (
      accessibility: g?['accessibility'] ?? false,
      usageAccess: g?['usageAccess'] ?? false,
      overlay: g?['overlay'] ?? false,
    );
  }

  /// The way apps are watched now, or null when none is granted.
  Future<WatchMethod?> method() async => pickWatchMethod(await grants());

  /// Opens the system's Accessibility settings; the app can't turn the
  /// service on itself.
  Future<void> openSettings() async {
    if (available) await _channel.invokeMethod<void>('openSettings');
  }

  /// Opens the system's Usage access settings.
  Future<void> openUsageAccess() async {
    if (available) await _channel.invokeMethod<void>('openUsageAccess');
  }

  /// Opens the system's "Display over other apps" for Doomread.
  Future<void> openOverlay() async {
    if (available) await _channel.invokeMethod<void>('openOverlay');
  }

  /// The apps on the device the user can launch, by label.
  Future<List<LaunchableApp>> apps() async {
    if (!available) return const [];
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>('apps');
    return [
      for (final a in list ?? const <Map<Object?, Object?>>[])
        (package: a['package']! as String, label: a['label']! as String),
    ];
  }

  /// Whether a Session is open, so the service should report apps, and
  /// start Doomread to hear them if it isn't running. [views] are the view
  /// ids to look for, by package; only those apps' screens are looked at.
  /// With [poll], usage access is polled, for when Accessibility is off.
  Future<void> setWatching({
    required bool on,
    Map<String, Set<String>> views = const {},
    bool poll = false,
  }) async {
    if (!available) return;
    await _channel.invokeMethod<void>('setWatching', {
      'on': on,
      'poll': poll,
      'views': [
        for (final MapEntry(:key, :value) in views.entries)
          for (final id in value) '$key|$id',
      ],
    });
  }

  /// Brings Doomread in front of the Watched app.
  Future<void> bringToFront() async {
    if (available) await _channel.invokeMethod<void>('bringToFront');
  }

  /// Launches [package], after a Slip.
  Future<void> open(String package) async {
    if (available) await _channel.invokeMethod<void>('open', package);
  }
}
