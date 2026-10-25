import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The way into Settings, on every tab's app bar. Read out as "Settings";
/// the tooltip only shows it, so it isn't read twice.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).settings;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: IconButton(
        icon: Icon(Icons.tune, semanticLabel: label),
        onPressed: () => context.push('/settings'),
      ),
    );
  }
}
