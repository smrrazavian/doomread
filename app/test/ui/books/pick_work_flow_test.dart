import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  testApp('tapping a Work in the Library makes it current, back on Today', (
    tester,
    db,
  ) async {
    final works = WorkRepository(db);
    final dune = await works.add(
      title: 'Dune',
      author: 'Frank Herbert',
      totalPages: 412,
      checkpoints: const [],
    );
    await works.add(
      title: 'Piranesi',
      author: 'Susanna Clarke',
      totalPages: 272,
      checkpoints: const [],
    );
    await works.setCurrent(dune);
    await pumpApp(tester, db);
    expect(find.text('Dune'), findsOne);

    await tester.tap(find.text(en.navBooks));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Piranesi'));
    await tester.pumpAndSettle();

    // Today, with the picked Work ready to Start.
    expect(find.text(en.tonightCard), findsOne);
    expect(find.text('Piranesi'), findsOne);
    expect(find.text('Dune'), findsNothing);
    expect(find.text(en.startReading), findsOne);
  });
}
