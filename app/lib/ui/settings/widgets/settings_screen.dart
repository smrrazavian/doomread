import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Each language is named in itself, so it can be found from either side.
  static const _languages = {'en': 'English', 'fa': 'فارسی'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<SettingsViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: RadioGroup<String>(
        groupValue: vm.locale.languageCode,
        onChanged: (code) => vm.setLocale(Locale(code!)),
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.account),
              onTap: () => context.push('/account'),
            ),
            ListTile(title: Text(l10n.language)),
            for (final MapEntry(:key, :value) in _languages.entries)
              RadioListTile<String>(value: key, title: Text(value)),
          ],
        ),
      ),
    );
  }
}
