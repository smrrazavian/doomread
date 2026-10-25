import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/reading/view_models/reading_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Stretch 2 · 38 min on this in all": once a minute is banked from earlier
/// Stretches, the time that never goes back, so the clock starting again
/// after a Pause doesn't read as time lost.
class SoFarLine extends StatelessWidget {
  const SoFarLine({super.key, this.textAlign});

  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReadingViewModel>();
    final all = vm.onThis;
    if (all - vm.shown < const Duration(minutes: 1)) {
      return const SizedBox.shrink();
    }
    return Text(
      AppLocalizations.of(context).stretchSoFar(vm.stretchNo, all.inMinutes),
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Palette.mute),
    );
  }
}
