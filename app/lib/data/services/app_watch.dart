import 'dart:io';

import 'package:flutter/services.dart';

/// An app the user can launch, as the picker of Watched apps lists it.
typedef LaunchableApp = ({String package, String label});

/// Which app is in front, from a small native edge on Android: an
/// AccessibilityService that only reports the app (ADR 0014). Whether it's
/// Watched is decided in core. Everywhere else every call does nothing.
class AppWatch {
  AppWatch() {
    if (available) _channel.setMethodCallHandler(_fromNative);
  }

  static const _channel = MethodChannel('doomread/watch');

  /// Whether this platform can watch apps at all.
  bool get available => Platform.isAndroid;

  /// Called with the app that just came to the front, while [setWatching]
  /// is on.
  void Function(String package, String label)? onForeground;

  Future<Object?> _fromNative(MethodCall call) async {
    if (call.method == 'foreground') {
      final args = call.arguments! as Map<Object?, Object?>;
      onForeground?.call(args['package']! as String, args['label']! as String);
    }
    return null;
  }

  /// Whether the user has turned the service on in the system settings.
  Future<bool> enabled() async =>
      available && (await _channel.invokeMethod<bool>('enabled') ?? false);

  /// Opens the system's Accessibility settings; the app can't turn the
  /// service on itself.
  Future<void> openSettings() async {
    if (available) await _channel.invokeMethod<void>('openSettings');
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
  /// start Doomread to hear them if it isn't running.
  Future<void> setWatching({required bool on}) async {
    if (available) await _channel.invokeMethod<void>('setWatching', on);
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
