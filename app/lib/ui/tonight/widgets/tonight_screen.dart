import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TonightScreen extends StatelessWidget {
  const TonightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 24),
        child: Column(
          // stretch so text hugs the start edge in both directions
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.navTonight, style: text.headlineSmall),
            const SizedBox(height: 4),
            Text(l10n.tonightEmpty, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}
