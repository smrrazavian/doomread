import 'dart:async';

import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/sync_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/data/services/auto_sync.dart';
import 'package:doomread/data/services/break_over_notification.dart';
import 'package:doomread/data/services/home_widget.dart';
import 'package:doomread/data/services/session_notification.dart';
import 'package:doomread/data/services/share_sheet.dart';
import 'package:doomread/domain/use_cases/first_run_use_case.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:doomread/domain/use_cases/sync_use_case.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/routing/router.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/planned_break/break_over_alarm.dart';
import 'package:doomread/ui/reading/live_notification.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread/ui/tonight/live_home_widget.dart';
import 'package:doomread/ui/tour/view_models/tour_view_model.dart';
import 'package:doomread/ui/urge/urge_watch.dart';
import 'package:doomread/ui/watch/view_models/watch_ask_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DoomreadApp extends StatefulWidget {
  const DoomreadApp({
    required this.db,
    this.auth,
    this.sync,
    this.clock,
    this.notification,
    this.breakOver,
    this.homeWidget,
    this.watch,
    this.share,
    this.phoneLocale,
    super.key,
  });

  final AppDatabase db;

  /// Stamps Session events and edits to Works, and runs the Reading timer.
  /// Tests pass a fixed one; the app uses the device's.
  final DateTime Function()? clock;

  /// The account on the sync server. Tests that never open the Account
  /// screen leave it out.
  final AuthRepository? auth;

  /// Syncs the signed-in account in the background, along with [auth].
  /// Tests that don't sync leave it out.
  final SyncRepository? sync;

  /// The ongoing notification while a Session runs. Tests pass a fake; the
  /// app uses the Android one, which does nothing on other platforms.
  final SessionNotification? notification;

  /// The "break's over" notification. Tests pass a fake; the app uses the
  /// Android one, which does nothing on other platforms.
  final BreakOverNotification? breakOver;

  /// The home screen widget. Tests pass a fake; the app uses the Android
  /// one, which does nothing on other platforms.
  final HomeWidget? homeWidget;

  /// Which app is in front, for Urges. Tests pass a fake; the app uses the
  /// Android one, which does nothing on other platforms.
  final AppWatch? watch;

  /// Where a shared poster goes. Tests pass a fake; the app uses the
  /// Android share sheet, or the Pictures folder on Linux.
  final ShareSheet? share;

  /// The phone's language. Tests pass one; the app reads the platform's.
  final Locale Function()? phoneLocale;

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
  late final StopDeletedSessionsUseCase _stopDeleted =
      StopDeletedSessionsUseCase(_works, _sessions);
  late final SettingsRepository _settingsRepository = SettingsRepository(
    widget.db,
  );
  late final SettingsViewModel _settings = SettingsViewModel(
    _settingsRepository,
    phoneLocale: widget.phoneLocale,
  );
  late final SessionNotification _notification =
      widget.notification ?? SessionNotification();
  late final LiveNotification _live;
  late final BreakOverAlarm _breakOver;
  AutoSync? _autoSync;
  late final HomeWidget _homeWidget = widget.homeWidget ?? HomeWidget();
  late final LiveHomeWidget _liveWidget;
  late final AppWatch _watch = widget.watch ?? AppWatch();
  late final UrgeWatch _urges;
  late final ShareSheet _share = widget.share ?? ShareSheet();
  late final TourViewModel _tour = TourViewModel(
    _settingsRepository,
    FirstRunUseCase(_settingsRepository, _works),
    language: () => _settings.locale,
  );

  /// Done once the settings and the tour have loaded: the first frame waits
  /// for it, so it's already in the saved language.
  late final Future<void> _ready;
  bool _loaded = false;
  late final GoRouter _router = buildRouter(_tour);
  late final WatchAskViewModel _watchAsk = WatchAskViewModel(
    _settingsRepository,
    _watch,
  )..addListener(_tellWatchReturn);
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.deferFirstFrame();
    _ready = _load();
    _live = LiveNotification(_sessions, _notification, _settings);
    _breakOver = BreakOverAlarm(
      _sessions,
      widget.breakOver ?? BreakOverNotification(),
      _settings,
    );
    _notification.onTapped = _openReading;
    unawaited(_openReadingIfTapped());
    if ((widget.auth, widget.sync) case (final auth?, final sync?)) {
      _autoSync = AutoSync(
        SyncUseCase(auth, sync, _works, _stopDeleted).call,
        triggers: [sync.localChanges, auth.changes],
      );
    }
    _liveWidget = LiveHomeWidget(_works, _sessions, _settings, _homeWidget);
    _homeWidget.onStart = _startFromWidget;
    _urges = UrgeWatch(_sessions, _watch, _settings)..onUrge = _openReading;
    unawaited(_startIfWidgetTapped());
    // A delete left unsettled when the app last closed.
    unawaited(_stopDeleted());
  }

  /// The first run is settled first, since an upgrade saves English then,
  /// and only then the settings are read.
  Future<void> _load() async {
    try {
      await _tour.load();
      await _settings.load();
    } finally {
      WidgetsBinding.instance.allowFirstFrame();
      if (mounted) setState(() => _loaded = true);
    }
  }

  /// Back from the Accessibility settings: says whether the "not yet"
  /// screen is on, or kindly that it's still off, with a way to try again.
  /// On the root messenger, so it shows on whichever screen the user is.
  void _tellWatchReturn() {
    final returned = _watchAsk.returned;
    final messenger = _messenger.currentState;
    if (returned == null || messenger == null) return;
    _watchAsk.clearReturned();
    final l10n = AppLocalizations.of(messenger.context);
    final on = returned == WatchReturn.on;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(on ? l10n.tourWatchOn : l10n.tourWatchOff),
          duration: Duration(seconds: on ? 4 : 10),
          action: on
              ? null
              : SnackBarAction(
                  label: l10n.tourWatchRetry,
                  onPressed: _watchAsk.retry.execute,
                ),
        ),
      );
  }

  /// When Start on the home screen widget started the app, starts that
  /// Session and opens its Reading screen once the first frame is up.
  Future<void> _startIfWidgetTapped() async {
    await _ready;
    final work = await _homeWidget.openedFrom();
    if (work == null || !mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await _startFromWidget(work);
  }

  Future<void> _startFromWidget(String workId) async {
    final id = await _liveWidget.start(workId);
    if (mounted) _openReading(id);
  }

  /// When a tap on the notification started the app, opens that Session's
  /// Reading screen over Tonight once the first frame is up.
  Future<void> _openReadingIfTapped() async {
    await _ready;
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
    _autoSync?.dispose();
    _live.dispose();
    _breakOver.dispose();
    _homeWidget.onStart = null;
    _liveWidget.dispose();
    _urges
      ..onUrge = null
      ..dispose();
    _settings.dispose();
    _router.dispose();
    _tour.dispose();
    _watchAsk
      ..removeListener(_tellWatchReturn)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_loaded
      ? const ColoredBox(color: Palette.night)
      : MultiProvider(
          providers: [
            Provider.value(value: _works),
            Provider.value(value: _sessions),
            Provider.value(value: _stopDeleted),
            Provider.value(value: _settingsRepository),
            Provider.value(value: _notification),
            Provider.value(value: _watch),
            Provider.value(value: _urges),
            Provider.value(value: _share),
            ChangeNotifierProvider.value(value: _settings),
            ChangeNotifierProvider.value(value: _tour),
            ChangeNotifierProvider.value(value: _watchAsk),
            if (widget.auth case final auth?) Provider.value(value: auth),
          ],
          child: ListenableBuilder(
            listenable: _settings,
            builder: (context, _) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: _messenger,
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
