import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testApp(
    'Persian text is never letter-spaced (it breaks the joined letters)',
    (tester, db) async {
      await SettingsRepository(db).setLocale(const Locale('fa'));
      await pumpApp(tester, db);

      // The theme as rendered, after Flutter localises it for Persian.
      final t = Theme.of(tester.element(find.text('امشب').first)).textTheme;
      final styles = {
        'displayLarge': t.displayLarge,
        'displayMedium': t.displayMedium,
        'displaySmall': t.displaySmall,
        'headlineLarge': t.headlineLarge,
        'headlineMedium': t.headlineMedium,
        'headlineSmall': t.headlineSmall,
        'titleLarge': t.titleLarge,
        'titleMedium': t.titleMedium,
        'titleSmall': t.titleSmall,
        'bodyLarge': t.bodyLarge,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
        'labelMedium': t.labelMedium,
        'labelSmall': t.labelSmall,
      };
      for (final MapEntry(:key, :value) in styles.entries) {
        expect(value?.letterSpacing ?? 0, 0, reason: key);
      }
    },
  );
}
