import 'dart:async';

import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/yalda.dart';
import 'package:doomread/ui/share/widgets/yalda_poster.dart';
import 'package:doomread/ui/share/yalda_night.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';

/// Tonight's line on Shab-e Yalda, by a painted pomegranate, and once
/// something's been read tonight, the way to the Yalda poster. Shown only
/// when there's a [night], so every other night it's nothing at all.
class YaldaTonight extends StatelessWidget {
  const YaldaTonight({required this.night, this.kind, super.key});

  final YaldaNight night;

  /// The current Work's kind, so the line says read, watch or listen;
  /// without one, the kind of what was read tonight.
  final WorkKind? kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final kind = this.kind ?? night.work?.kind ?? WorkKind.paperBook;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(top: 2, end: 10),
                child: Pomegranate(),
              ),
              Expanded(
                child: Text(
                  l10n.yaldaTonight(kind.name),
                  style: text.bodyMedium!.copyWith(color: YaldaPalette.me),
                ),
              ),
            ],
          ),
          if (canShareYalda(context, night))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => unawaited(showYaldaPoster(context, night)),
                child: Text(l10n.yaldaShare),
              ),
            ),
        ],
      ),
    );
  }
}
