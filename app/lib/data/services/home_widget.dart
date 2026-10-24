import 'dart:io';

import 'package:flutter/services.dart';

/// Everything the home screen widget shows, already in the app's language:
/// the native side only stores it and draws it.
typedef HomeWidgetContent = ({
  String title,
  String? road,
  String? evenings,
  String lit,
  String dark,

  /// When tonight's Window goes dark again; null while it isn't lit.
  DateTime? litUntil,
  String button,

  /// The open Session the button goes back to.
  String? sessionId,

  /// The Work the button starts a Session with, when none is open.
  String? workId,
  bool rtl,

  /// How many floors the user's Building has: one per Finish. The Building
  /// widget draws them under tonight's Window.
  int floors,
});

/// The home screen widgets, drawn by a small native edge with Glance on
/// Android (ADR 0011): the Road with Start, and the Building with tonight's
/// Window. Both draw the one push. Everywhere else every call does nothing.
class HomeWidget {
  HomeWidget() {
    if (_android) _channel.setMethodCallHandler(_fromNative);
  }

  static const _channel = MethodChannel('doomread/home_widget');

  bool get _android => Platform.isAndroid;

  /// Called with a Work's id when the user taps Start on the widget while
  /// the app is alive.
  void Function(String workId)? onStart;

  Future<Object?> _fromNative(MethodCall call) async {
    if (call.method == 'start') onStart?.call(call.arguments! as String);
    return null;
  }

  Future<void> update(HomeWidgetContent content) async {
    if (!_android) return;
    await _channel.invokeMethod<void>('update', {
      'title': content.title,
      'road': content.road,
      'evenings': content.evenings,
      'lit': content.lit,
      'dark': content.dark,
      'litUntil': content.litUntil?.millisecondsSinceEpoch,
      'button': content.button,
      'sessionId': content.sessionId,
      'workId': content.workId,
      'rtl': content.rtl,
      'floors': content.floors,
    });
  }

  /// The Work whose Start on the widget started the app, once; null if the
  /// app was started some other way.
  Future<String?> openedFrom() async =>
      _android ? await _channel.invokeMethod<String>('openedFrom') : null;
}
