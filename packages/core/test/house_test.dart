import 'package:doomread_core/doomread_core.dart';
import 'package:test/test.dart';

void main() {
  // Tonight is 22 October 2026, 21:00.
  final now = DateTime(2026, 10, 22, 21);
  List<HouseWindow> house(List<DateTime> before) =>
      houseWindows(now: now, before: before);

  test("with no earlier Sessions, only the user's own Window is lit", () {
    expect(house(const []), [HouseWindow.yours]);
  });

  test('each earlier Session tonight lights its own Window', () {
    expect(
      house([DateTime(2026, 10, 22, 19), DateTime(2026, 10, 22, 20, 30)]),
      [
        HouseWindow.yours,
        HouseWindow.earlierTonight,
        HouseWindow.earlierTonight,
      ],
    );
  });

  test('a past evening lights one Window, however many Sessions it had', () {
    expect(
      house([
        DateTime(2026, 10, 20, 20),
        DateTime(2026, 10, 20, 22),
        // Past midnight still counts toward the evening of the 20th.
        DateTime(2026, 10, 21, 1),
        DateTime(2026, 10, 18, 21),
      ]),
      [HouseWindow.yours, HouseWindow.pastEvening, HouseWindow.pastEvening],
    );
  });

  test("after midnight, the evening's earlier Sessions are still tonight", () {
    expect(
      houseWindows(
        now: DateTime(2026, 10, 23, 1),
        before: [DateTime(2026, 10, 22, 22), DateTime(2026, 10, 22, 3)],
      ),
      [HouseWindow.yours, HouseWindow.earlierTonight, HouseWindow.pastEvening],
    );
  });

  test('Sessions stamped after now are never shown', () {
    expect(house([DateTime(2026, 10, 22, 22), DateTime(2026, 10, 25, 21)]), [
      HouseWindow.yours,
    ]);
  });

  test('tonight comes before past evenings, whatever the journal order', () {
    expect(
      house([
        DateTime(2026, 10, 10, 21),
        DateTime(2026, 10, 22, 19),
        DateTime(2026, 10, 21, 21),
      ]),
      [
        HouseWindow.yours,
        HouseWindow.earlierTonight,
        HouseWindow.pastEvening,
        HouseWindow.pastEvening,
      ],
    );
  });
}
