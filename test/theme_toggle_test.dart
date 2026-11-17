import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/theme/theme_controller.dart';
import 'package:daalsetu/modules/settings/view/settings_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  test('ThemeController switches and persists light and dark theme modes', () async {
    final controller = Get.put(ThemeController());

    // Initial state should be light
    expect(controller.themeMode.value, ThemeMode.light);
    expect(controller.isDark, false);

    // Switch to dark mode
    await controller.setDarkTheme();
    expect(controller.themeMode.value, ThemeMode.dark);
    expect(controller.isDark, true);

    // Verify stored in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'dark');

    // Toggle theme
    await controller.toggleTheme();
    expect(controller.themeMode.value, ThemeMode.light);
    expect(controller.isDark, false);
    expect(prefs.getString('themeMode'), 'light');

    // Set system theme
    await controller.setSystemTheme();
    expect(controller.themeMode.value, ThemeMode.system);
    expect(prefs.getString('themeMode'), 'system');
  });

  testWidgets('AppTheme defines consistent dark and light palettes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SizedBox(),
    ));

    final dark = AppTheme.darkTheme;
    expect(dark.brightness, Brightness.dark);
    expect(dark.scaffoldBackgroundColor, AppTheme.bgDarkNavy);
    expect(dark.colorScheme.primary, AppTheme.secondaryOrange);
    expect(dark.dialogTheme.backgroundColor, AppTheme.cardColor);

    final light = AppTheme.lightTheme;
    expect(light.brightness, Brightness.light);
    expect(light.scaffoldBackgroundColor, AppTheme.bgLight);
    expect(light.colorScheme.primary, AppTheme.secondaryOrange);
    expect(light.dialogTheme.backgroundColor, AppTheme.cardLight);
  });

  testWidgets('SettingsScreen displays PREFERENCES section and Dark Theme toggle', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final themeController = Get.put(ThemeController(), permanent: true);
    themeController.themeMode.value = ThemeMode.light;

    await tester.pumpWidget(GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value,
      home: SettingsScreen(),
    ));
    await tester.pump();

    // Verify Preferences section label
    expect(find.text('PREFERENCES'), findsOneWidget);

    // Verify Dark Theme title and subtitle
    expect(find.text('Dark Theme'), findsOneWidget);
    expect(find.text('Light background with fresh tones'), findsOneWidget);

    // Tap on Dark Theme tile
    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();

    // ThemeController should now be dark
    expect(themeController.isDark, true);
    expect(find.text('Dark background with high contrast'), findsOneWidget);

    // Tap again to switch back
    await tester.tap(find.text('Dark Theme'));
    await tester.pumpAndSettle();

    expect(themeController.isDark, false);
    expect(find.text('Light background with fresh tones'), findsOneWidget);
  });
}
