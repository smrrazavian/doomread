import 'dart:io';

import 'package:flutter/services.dart';

/// The ongoing notification while a Session runs, drawn by a small native
/// edge on Android (ADR 0009). Everywhere else every call does nothing.
class SessionNotification {
  SessionNotification() {
    if (_android) _channel.setMethodCallHandler(_fromNative);
  }

  static const _channel = MethodChannel('doomread/session_notification');

  bool get _android => Platform.isAndroid;

  /// Called with a Session's id when the user taps its notification while
  /// the app is alive.
  void Function(String sessionId)? onTapped;

  Future<Object?> _fromNative(MethodCall call) async {
    if (call.method == 'tapped') onTapped?.call(call.arguments! as String);
    return null;
  }

  /// Whether the system would still show its notification permission prompt:
  /// Android 13 or later, and not granted yet.
  Future<bool> canAsk() async =>
      _android && (await _channel.invokeMethod<bool>('canAsk') ?? false);

  /// Shows the system prompt; true if the user allowed notifications.
  Future<bool> ask() async =>
      _android && (await _channel.invokeMethod<bool>('ask') ?? false);

  /// Shows or updates the notification for [sessionId]. While a Stretch runs,
  /// [runningSince] is its start and the system counts up from it, so nothing
  /// in the app has to keep ticking; null shows [text] alone.
  Future<void> show({
    required String sessionId,
    required String title,
    required String text,
    DateTime? runningSince,
  }) async {
    if (!_android) return;
    await _channel.invokeMethod<void>('show', {
      'sessionId': sessionId,
      'title': title,
      'text': text,
      'runningSince': runningSince?.millisecondsSinceEpoch,
    });
  }

  Future<void> cancel() async {
    if (_android) await _channel.invokeMethod<void>('cancel');
  }

  /// The Session whose notification started the app, once; null if the app
  /// was started some other way.
  Future<String?> openedFrom() async =>
      _android ? await _channel.invokeMethod<String>('openedFrom') : null;
}
