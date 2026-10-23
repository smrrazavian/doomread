import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Tone's name, as the user picks it.
String toneName(AppLocalizations l10n, Tone tone) => switch (tone) {
  Tone.chill => l10n.toneChill,
  Tone.spicy => l10n.toneSpicy,
  Tone.mom => l10n.toneMom,
};

/// A real line in [tone]: what the Urge says when Instagram opens.
String toneSample(BuildContext context, Tone tone) => voice(
  Moment.urge,
  tone,
  Localizations.localeOf(context).languageCode,
  const {'app': 'Instagram'},
);

/// Chill, Spicy or Mom mode, each with what it sounds like.
class ToneScreen extends StatelessWidget {
  const ToneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tone)),
      body: RadioGroup<Tone>(
        groupValue: vm.tone,
        onChanged: (t) => vm.setTone(t!),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(l10n.toneHint, style: text.bodyMedium),
            ),
            for (final t in Tone.values)
              RadioListTile<Tone>(
                value: t,
                title: Text(toneName(l10n, t)),
                subtitle: Text(toneSample(context, t)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The Tone, offered on Tonight before the first Work: the three names,
/// and what the picked one sounds like.
class TonePicker extends StatelessWidget {
  const TonePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vm = context.watch<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.toneAsk, style: text.bodyMedium),
        const SizedBox(height: 12),
        SegmentedButton<Tone>(
          showSelectedIcon: false,
          segments: [
            for (final t in Tone.values)
              ButtonSegment(value: t, label: Text(toneName(l10n, t))),
          ],
          selected: {vm.tone},
          onSelectionChanged: (s) => vm.setTone(s.single),
        ),
        const SizedBox(height: 12),
        Text(toneSample(context, vm.tone), style: text.bodySmall),
      ],
    );
  }
}
