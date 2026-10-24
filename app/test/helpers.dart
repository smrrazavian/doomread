import 'dart:typed_data';

import 'package:doomread/app.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/data/services/break_over_notification.dart';
import 'package:doomread/data/services/home_widget.dart';
import 'package:doomread/data/services/session_notification.dart';
import 'package:doomread/data/services/share_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget test of the whole app on a fresh in-memory database.
///
/// drift cancels a stream query on a zero-length timer after its last
/// listener leaves, so the app is unmounted and that timer flushed before the
/// test ends; otherwise Flutter reports a pending timer and close() hangs.
void testApp(
  String description,
  Future<void> Function(WidgetTester tester, AppDatabase db) body,
) {
  testWidgets(description, (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await body(tester, db);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}

/// Starts the app on [db] and waits for it to settle. Widget tests run on
/// fake time, so Session tests pass a [clock] they move by hand.
///
/// Reduced motion is on unless [reduceMotion] is false: the user's Window in
/// the House pulses for as long as the Reading screen is open, so the app
/// would otherwise never settle.
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  DateTime Function()? clock,
  SessionNotification? notification,
  bool reduceMotion = true,
  BreakOverNotification? breakOver,
  HomeWidget? homeWidget,
  AppWatch? watch,
  ShareSheet? share,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    DoomreadApp(
      db: db,
      clock: clock,
      notification: notification,
      breakOver: breakOver,
      homeWidget: homeWidget,
      watch: watch ?? FakeAppWatch(),
      share: share ?? FakeShareSheet(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Stands in for the Android notification and records what the app did.
class FakeSessionNotification implements SessionNotification {
  FakeSessionNotification({this.askable = false, this.opened});

  /// Whether the system would still show its permission prompt.
  bool askable;

  /// How many times the system prompt was shown.
  int asks = 0;

  /// The Session whose notification "started" the app.
  String? opened;

  /// What the notification shows now; null when there is none.
  ({String sessionId, String title, String text, DateTime? runningSince})?
  shown;

  @override
  void Function(String sessionId)? onTapped;

  @override
  Future<bool> canAsk() async => askable;

  @override
  Future<bool> ask() async {
    asks++;
    askable = false;
    return true;
  }

  @override
  Future<void> show({
    required String sessionId,
    required String title,
    required String text,
    DateTime? runningSince,
  }) async => shown = (
    sessionId: sessionId,
    title: title,
    text: text,
    runningSince: runningSince,
  );

  @override
  Future<void> cancel() async => shown = null;

  @override
  Future<String?> openedFrom() async {
    final id = opened;
    opened = null;
    return id;
  }
}

/// Stands in for the Android "break's over" notification.
class FakeBreakOverNotification implements BreakOverNotification {
  /// What's set now; null when nothing is.
  ({String sessionId, DateTime at, String title, String text})? set;

  @override
  Future<void> schedule({
    required String sessionId,
    required DateTime at,
    required String title,
    required String text,
  }) async => set = (sessionId: sessionId, at: at, title: title, text: text);

  @override
  Future<void> cancel() async => set = null;
}

/// Stands in for the Android home screen widget and records what it was sent.
class FakeHomeWidget implements HomeWidget {
  FakeHomeWidget({this.opened});

  /// The Work whose Start on the widget "started" the app.
  String? opened;

  /// Everything sent, oldest first.
  final List<HomeWidgetContent> sent = [];

  HomeWidgetContent? get shown => sent.lastOrNull;

  @override
  void Function(String workId)? onStart;

  @override
  Future<void> update(HomeWidgetContent content) async => sent.add(content);

  @override
  Future<String?> openedFrom() async {
    final id = opened;
    opened = null;
    return id;
  }
}

/// Stands in for the Android app watcher and records what the app did.
class FakeAppWatch implements AppWatch {
  FakeAppWatch({
    this.isEnabled = true,
    this.usageAccess = false,
    this.overlay = false,
    this.installed = const [],
  });

  /// Whether the user has turned the Accessibility service on.
  bool isEnabled;

  /// Whether the user has granted usage access, and display over other apps.
  bool usageAccess;
  bool overlay;

  final List<LaunchableApp> installed;

  /// What the app last said about watching.
  bool watching = false;

  /// The views the service was last asked to look for, by package.
  Map<String, Set<String>> views = const {};

  /// Whether usage access was last asked to be polled.
  bool polling = false;

  /// How many times the app came to the front for an Urge.
  int fronts = 0;

  /// The app launched last, after a Slip.
  String? opened;

  /// How many times the Accessibility, Usage access and overlay settings
  /// were opened.
  int settingsOpened = 0;
  int usageOpened = 0;
  int overlayOpened = 0;

  @override
  bool get available => true;

  @override
  void Function(String package, String label, Set<String> views)? onForeground;

  @override
  Future<WatchGrants> grants() async =>
      (accessibility: isEnabled, usageAccess: usageAccess, overlay: overlay);

  @override
  Future<WatchMethod?> method() async => pickWatchMethod(await grants());

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> openUsageAccess() async => usageOpened++;

  @override
  Future<void> openOverlay() async => overlayOpened++;

  @override
  Future<List<LaunchableApp>> apps() async => installed;

  @override
  Future<void> setWatching({
    required bool on,
    Map<String, Set<String>> views = const {},
    bool poll = false,
  }) async {
    watching = on;
    this.views = views;
    polling = poll;
  }

  @override
  Future<void> bringToFront() async => fronts++;

  /// Launching an app reports it straight away, as the service would,
  /// before the journal has caught up.
  @override
  Future<void> open(String package) async {
    opened = package;
    onForeground?.call(package, package, const {});
  }
}

/// Stands in for the share sheet: records what it was given and "saves" it
/// to a made-up Pictures folder.
class FakeShareSheet implements ShareSheet {
  final List<({Uint8List png, String name, String title})> shared = [];

  @override
  bool get available => true;

  @override
  Future<String?> sharePng(
    Uint8List png, {
    required String name,
    required String title,
  }) async {
    shared.add((png: png, name: name, title: title));
    return '/home/me/Pictures/$name';
  }
}
