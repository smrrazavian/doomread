import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the real fonts so golden images show actual Latin and Persian text
/// (Flutter tests otherwise draw every glyph as a box).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  const families = {
    'Literata': ['Literata.ttf'],
    'BricolageGrotesque': ['BricolageGrotesque.ttf'],
    'NotoNaskhArabic': ['NotoNaskhArabic.ttf'],
    'VazirmatnUI': [
      'Vazirmatn-UI-Regular.ttf',
      'Vazirmatn-UI-Medium.ttf',
      'Vazirmatn-UI-Bold.ttf',
    ],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(_bytes('assets/fonts/$f'));
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      _bytes(
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
        'material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await icons.load();
  await testMain();
}

Future<ByteData> _bytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());
