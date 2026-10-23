import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// What the app says at [moment], in the user's Tone and this locale. Core's
/// Voice keeps it kind after a Slip.
String say(
  BuildContext context,
  Moment moment, [
  Map<String, String> facts = const {},
]) => voice(
  moment,
  context.watch<SettingsViewModel>().tone,
  Localizations.localeOf(context).languageCode,
  facts,
);
