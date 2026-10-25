import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/core/number_format.dart';
import 'package:doomread/ui/core/theme.dart';
import 'package:doomread/ui/reading/view_models/reading_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A Session's clock, the time in one go, big, and the pause button too,
/// for a book's Session and a Task's alike: a tap pauses it, and paused,
/// it goes quiet until a tap keeps it going. The line under it says which.
class SessionClock extends StatelessWidget {
  const SessionClock({this.centered = false, super.key});

  /// Centered, as at the desk; otherwise at the start, as in Reading.
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<ReadingViewModel>();
    final running = vm.session?.current != null;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: running ? l10n.taskPause : l10n.taskResume,
          excludeSemantics: true,
          child: InkWell(
            key: const Key('sessionClock'),
            borderRadius: BorderRadius.circular(24),
            onTap: running ? vm.pause.execute : vm.resume.execute,
            // Past an hour, or in large text, it shrinks to fit.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                // Clocks don't mirror in Persian.
                textDirection: TextDirection.ltr,
                children: [
                  // Balances the pause mark, so a centered time stays put.
                  if (centered) const SizedBox(width: _markWidth),
                  Text(
                    formatClock(vm.shown, locale),
                    textDirection: TextDirection.ltr,
                    style: text.headlineSmall!.copyWith(
                      fontSize: locale.languageCode == 'fa' ? 68 : 72,
                      height: 1.1,
                      color: running ? Palette.paper : Palette.mute,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  // Paused, a pause mark beside the time, so it reads as
                  // stopped at a glance and not only as dimmer. Its room is
                  // kept while running, so the time never jumps.
                  SizedBox(
                    width: _markWidth,
                    child: running
                        ? null
                        : const Icon(
                            Icons.pause,
                            size: 36,
                            color: Palette.mute,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          running ? l10n.taskClockRunning : l10n.taskClockPaused,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: text.bodySmall?.copyWith(
            color: running ? Palette.mute : Palette.lamp,
          ),
        ),
      ],
    );
  }
}

/// The room beside the time for the pause mark.
const _markWidth = 44.0;
