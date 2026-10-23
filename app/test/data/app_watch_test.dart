import 'package:doomread/data/services/app_watch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WatchMethod? pick({
    bool accessibility = false,
    bool usageAccess = false,
    bool overlay = false,
  }) => pickWatchMethod((
    accessibility: accessibility,
    usageAccess: usageAccess,
    overlay: overlay,
  ));

  test('Accessibility when it is on, whatever else is granted', () {
    expect(pick(accessibility: true), WatchMethod.accessibility);
    expect(
      pick(accessibility: true, usageAccess: true, overlay: true),
      WatchMethod.accessibility,
    );
  });

  test('usage access otherwise, with the overlay to come to the front', () {
    expect(pick(usageAccess: true, overlay: true), WatchMethod.usageAccess);
  });

  test('none when usage access or the overlay is missing', () {
    expect(pick(), isNull);
    expect(pick(usageAccess: true), isNull);
    expect(pick(overlay: true), isNull);
  });
}
