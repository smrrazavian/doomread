import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// gen-l10n quietly falls back to English for a missing message, so a
/// language with gaps would ship half in English. This catches it instead.
void main() {
  Set<String> messages(File arb) =>
      (jsonDecode(arb.readAsStringSync()) as Map<String, Object?>).keys
          .where((k) => !k.startsWith('@'))
          .toSet();

  final template = messages(File('lib/l10n/app_en.arb'));
  final arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'));

  for (final arb in arbs) {
    test('${arb.uri.pathSegments.last} has every message, and no extras', () {
      final keys = messages(arb);
      expect(template.difference(keys), isEmpty, reason: 'missing');
      expect(keys.difference(template), isEmpty, reason: 'not in app_en.arb');
    });
  }
}
