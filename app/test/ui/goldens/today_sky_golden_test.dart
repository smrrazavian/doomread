import 'package:doomread/data/repositories/settings_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  // Saturday 24 October 2026, at three times of the day.
  final times = {
    'morning': DateTime(2026, 10, 24, 8, 30),
    'dusk': DateTime(2026, 10, 24, 18),
    'night': DateTime(2026, 10, 24, 22),
  };

  for (final lang in ['en', 'fa']) {
    final fa = lang == 'fa';
    for (final MapEntry(key: name, value: now) in times.entries) {
      testApp("Today's sky at $name, in $lang", (tester, db) async {
        final works = WorkRepository(db);
        final day = DateTime(2026, 10, 24);
        for (final task
            in fa
                ? [
                    'جواب ایمیل‌های مشتری',
                    'نوشتن گزارش فصل سوم',
                    'زنگ زدن به بانک',
                  ]
                : [
                    'Answer the client emails',
                    'Write the Q3 report',
                    'Call the bank',
                  ]) {
          await works.addTask(name: task, day: day);
        }
        await works.add(
          title: fa ? 'بازمانده‌ی روز' : 'The Remains of the Day',
          author: fa ? 'کازوئو ایشی‌گورو' : 'Kazuo Ishiguro',
          totalPages: 245,
          checkpoints: const [],
        );
        tester.view
          ..physicalSize = const Size(720, 1560)
          ..devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await SettingsRepository(db).setLocale(Locale(lang));
        await pumpApp(tester, db, clock: () => now);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('today_sky_${name}_$lang.png'),
        );
      });
    }
  }
}
