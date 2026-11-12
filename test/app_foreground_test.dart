import 'package:daalsetu/utils/global_error_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('screen off and the first seconds after unlock count as not ready for popups', (tester) async {
    AppForeground.ensureTracking();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(AppForeground.isActive, isFalse); // screen off: polls skip, no popup

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(AppForeground.isActive, isTrue);
    expect(AppForeground.secondsSinceResume, lessThan(5)); // just unlocked: still quiet
  });
}
