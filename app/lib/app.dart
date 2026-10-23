import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/session_repository.dart';
import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/routing/router.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DoomreadApp extends StatefulWidget {
  const DoomreadApp({required this.db, this.auth, this.clock, super.key});

  final AppDatabase db;

  /// Stamps Session events and runs the Reading timer. Tests pass a fixed
  /// one; the app uses the device's.
  final DateTime Function()? clock;

  /// The account on the sync server. Tests that never open the Account
  /// screen leave it out.
  final AuthRepository? auth;

  @override
  State<DoomreadApp> createState() => _DoomreadAppState();
}

class _DoomreadAppState extends State<DoomreadApp> {
  late final WorkRepository _works = WorkRepository(widget.db);
  late final SessionRepository _sessions = SessionRepository(
    widget.db,
    clock: widget.clock,
  );
  late final SettingsViewModel _settings = SettingsViewModel(
    SettingsRepository(widget.db),
  )..load();
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _settings.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: _works),
      Provider.value(value: _sessions),
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
