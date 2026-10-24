import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:flutter/material.dart';

/// One line from the tour, in place on the screen it explains, with its
/// answers under it: "Got it" unless [actions] are given. Never an overlay.
class HintCard extends StatelessWidget {
  const HintCard({required this.text, this.onGotIt, this.actions, super.key});

  final String text;
  final VoidCallback? onGotIt;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.panel,
          border: Border.all(color: Palette.lamp.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.only(top: 2, end: 12),
                      child: Icon(
                        Icons.lightbulb_outlined,
                        size: 18,
                        color: Palette.lamp,
                      ),
                    ),
                    Expanded(child: Text(text, style: style)),
                  ],
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children:
                    actions ??
                    [
                      TextButton(
                        key: const Key('hintGotIt'),
                        onPressed: onGotIt,
                        child: Text(l10n.tourGotIt),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
