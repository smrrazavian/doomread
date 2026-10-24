import 'dart:async';

import 'package:doomread/data/services/app_watch.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Opens the system's Accessibility settings and, when the user comes back,
/// says whether the "not yet" screen is on now, or kindly that it's still
/// off, with a way to try again. Shown on the app's root messenger, so it
/// arrives whichever screen the user comes back to.
Future<void> openWatchSettings(BuildContext context) => _open(
  context.read<AppWatch>(),
  ScaffoldMessenger.of(context),
  AppLocalizations.of(context),
);

Future<void> _open(
  AppWatch watch,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  late final AppLifecycleListener back;
  back = AppLifecycleListener(
    onResume: () {
      back.dispose();
      unawaited(_tell(watch, messenger, l10n));
    },
  );
  await watch.openSettings();
}

Future<void> _tell(
  AppWatch watch,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  final on = (await watch.grants()).accessibility;
  if (!messenger.mounted) return;
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
                onPressed: () => unawaited(_open(watch, messenger, l10n)),
              ),
      ),
    );
}
