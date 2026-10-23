import 'dart:io';

import 'package:flutter/services.dart';

/// The "break's over" notification, set for when a Planned break ends. On
/// Android a small native edge sets an alarm for it (ADR 0009's pattern):
/// exact when the user allows exact alarms, otherwise inexact. Everywhere
/// else every call does nothing.
class BreakOverNotification {
  static const _channel = MethodChannel('doomread/break_over');

  bool get _android => Platform.isAndroid;

  /// Sets the notification for [at], replacing any set before. The text is
  /// already in the app's language, since the alarm may go off after the
  /// app was killed. A tap on it opens [sessionId]'s Reading screen.
  Future<void> schedule({
    required String sessionId,
    required DateTime at,
    required String title,
    required String text,
  }) async {
    if (!_android) return;
    await _channel.invokeMethod<void>('schedule', {
      'sessionId': sessionId,
      'at': at.millisecondsSinceEpoch,
      'title': title,
      'text': text,
    });
  }

  /// Unsets the alarm, and takes the notification away if it's showing.
  Future<void> cancel() async {
    if (_android) await _channel.invokeMethod<void>('cancel');
  }
}
