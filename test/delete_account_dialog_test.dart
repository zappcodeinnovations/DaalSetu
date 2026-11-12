import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/settings/view/settings_page.dart';
import 'package:daalsetu/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'role': 'seller'});
    Get.put(ThemeController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SettingsScreen: tap Delete Account, then Cancel safely returns to SettingsScreen',
      (WidgetTester tester) async {
    // Set a large screen size to avoid clipping
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      GetMaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final deleteTileFinder = find.text('Delete Account');
    expect(deleteTileFinder, findsOneWidget);

    // Tap Delete Account tile
    await tester.tap(deleteTileFinder);
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('Delete account?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify dialog closed and Settings screen remains fully intact
    expect(find.text('Delete account?'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
  });
}
