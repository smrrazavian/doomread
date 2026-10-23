import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// The prominent disclosure Google Play asks for before the Accessibility
/// settings: what the service sees, what it's for, and that nothing leaves
/// the phone. It needs an affirmative tap; true when the user agreed.
Future<bool> askToWatch(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _WatchDisclosure(),
    ) ??
    false;

class _WatchDisclosure extends StatelessWidget {
  const _WatchDisclosure();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: Palette.panel,
      icon: const Icon(Icons.visibility_outlined, color: Palette.lamp),
      title: Text(l10n.watchAskTitle),
      content: SingleChildScrollView(child: Text(l10n.watchAskBody)),
      actions: [
        TextButton(
          key: const Key('watchNotNow'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.watchAskNotNow),
        ),
        FilledButton(
          key: const Key('watchAgree'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.watchAskAgree),
        ),
      ],
    );
  }
}
