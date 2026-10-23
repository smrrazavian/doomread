import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/data/services/app_database.dart';
import 'package:doomread/ui/books/view_models/work_form_view_model.dart';
import 'package:doomread/utils/result.dart';
import 'package:doomread_core/doomread_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkRepository works;
  late WorkFormViewModel vm;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    works = WorkRepository(db);
    vm = WorkFormViewModel(works);
  });
  tearDown(() => db.close());

  WorkDraft draft({int pages = 245, List<int> checkpoints = const [34, 66]}) =>
      WorkDraft(
        title: 'The Remains of the Day',
        author: 'Kazuo Ishiguro',
        totalPages: pages,
        checkpoints: checkpoints,
      );

  test('valid input saves the Work', () async {
    await vm.save.execute(draft());
    expect(vm.save.result, isA<Ok<String>>());
    expect((await works.watchAll().first).single.totalPages, 245);
  });

  test(
    'zero pages is refused with a pages problem and nothing is saved',
    () async {
      await vm.save.execute(draft(pages: 0));
      expect(vm.problems, {WorkProblem.noPages});
      expect(await works.watchAll().first, isEmpty);
    },
  );

  test('a Checkpoint past the last page is refused', () async {
    await vm.save.execute(draft(checkpoints: [34, 300]));
    expect(vm.problems, {WorkProblem.checkpointPastEnd});
    expect(await works.watchAll().first, isEmpty);
  });

  test('a series is saved as a series, in episodes', () async {
    await vm.save.execute(
      WorkDraft(
        title: 'Dark',
        author: '',
        totalPages: 10,
        checkpoints: const [],
        kind: WorkKind.series,
      ),
    );
    final dark = (await works.watchAll().first).single;
    expect(dark.kind, WorkKind.series);
    expect(dark.totalPages, 10);
  });

  test('a missing title is refused', () async {
    await vm.save.execute(
      WorkDraft(title: '  ', author: '', totalPages: 10, checkpoints: const []),
    );
    expect(vm.problems, {WorkProblem.noTitle});
  });
}
