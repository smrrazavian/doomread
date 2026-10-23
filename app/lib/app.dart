import 'dart:async';

import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/data/services/break_over_notification.dart';
import 'package:doomread/data/services/session_notification.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/routing/router.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/planned_break/break_over_alarm.dart';
import 'package:doomread/ui/reading/live_notification.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DoomreadApp extends StatefulWidget {
  const DoomreadApp({
    required this.db,
    this.auth,
    this.clock,
    this.notification,
    this.breakOver,
    super.key,
  });

  final AppDatabase db;

  /// Stamps Session events and edits to Works, and runs the Reading timer.
  /// Tests pass a fixed one; the app uses the device's.
  final DateTime Function()? clock;

  /// The account on the sync server. Tests that never open the Account
  /// screen leave it out.
  final AuthRepository? auth;

  /// The ongoing notification while a Session runs. Tests pass a fake; the
  /// app uses the Android one, which does nothing on other platforms.
  final SessionNotification? notification;

  /// The "break's over" notification. Tests pass a fake; the app uses the
  /// Android one, which does nothing on other platforms.
  final BreakOverNotification? breakOver;

  @override
  State<DoomreadApp> createState() => _DoomreadAppState();
}

class _DoomreadAppState extends State<DoomreadApp> {
  late final WorkRepository _works = WorkRepository(
    widget.db,
    clock: widget.clock,
  );
  late final SessionRepository _sessions = SessionRepository(
    widget.db,
    clock: widget.clock,
  );
  late final SettingsRepository _settingsRepository = SettingsRepository(
    widget.db,
  );
  late final SettingsViewModel _settings = SettingsViewModel(
    _settingsRepository,
  )..load();
  late final SessionNotification _notification =
      widget.notification ?? SessionNotification();
  late final LiveNotification _live;
  late final BreakOverAlarm _breakOver;
  final GoRouter _router = buildRouter();

  @override
  void initState() {
    super.initState();
    _live = LiveNotification(_sessions, _notification, _settings);
    _breakOver = BreakOverAlarm(
      _sessions,
      widget.breakOver ?? BreakOverNotification(),
      _settings,
    );
    _notification.onTapped = _openReading;
    unawaited(_openReadingIfTapped());
  }

  /// When a tap on the notification started the app, opens that Session's
  /// Reading screen over Tonight once the first frame is up.
  Future<void> _openReadingIfTapped() async {
    final id = await _notification.openedFrom();
    if (id == null || !mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _openReading(id);
  }

  void _openReading(String sessionId) {
    final path = '/reading/$sessionId';
    if (_router.routerDelegate.currentConfiguration.uri.path != path) {
      unawaited(_router.push(path));
    }
  }

  @override
  void dispose() {
    _notification.onTapped = null;
    _live.dispose();
    _breakOver.dispose();
    _settings.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: _works),
      Provider.value(value: _sessions),
      Provider.value(value: _settingsRepository),
      Provider.value(value: _notification),
      ChangeNotifierProvider.value(value: _settings),
      if (widget.auth case final auth?) Provider.value(value: auth),
    ],
    child: ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
        locale: _settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(_settings.locale),
        routerConfig: _router,
      ),
    ),
  );
}
