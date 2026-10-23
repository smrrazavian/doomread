import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  SessionEndDraft draft(int? page) =>
      SessionEndDraft(page: page, fromPage: 142, totalPages: 245);

  test('a page between the start and the last page can be saved', () {
    expect(draft(156).problems, isEmpty);
    expect(draft(142).problems, isEmpty);
    expect(draft(245).problems, isEmpty);
  });

  test('the page is required', () {
    expect(draft(null).problems, {SessionEndProblem.noPage});
  });

  test('a page before the start or past the end is refused', () {
    expect(draft(141).problems, {SessionEndProblem.pageOutOfRange});
    expect(draft(246).problems, {SessionEndProblem.pageOutOfRange});
  });
}
