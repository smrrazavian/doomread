import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/routing/router.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DoomreadApp extends StatefulWidget {
  const DoomreadApp({required this.settings, super.key});

  final SettingsRepository settings;

  @override
  State<DoomreadApp> createState() => _DoomreadAppState();
}

class _DoomreadAppState extends State<DoomreadApp> {
  late final SettingsViewModel _settings = SettingsViewModel(widget.settings)
    ..load();
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _settings.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _settings,
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
