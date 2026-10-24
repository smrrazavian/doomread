import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each haptic the app asks for from now on.
List<Object?> haptics(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  final calls = <Object?>[];
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}
