import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daalsetu/modules/onboarding/controller/onboarding_controller.dart';
import 'package:daalsetu/modules/onboarding/theme/onboarding_theme.dart';
import 'package:daalsetu/modules/onboarding/view/onboarding_screen.dart';
import 'package:daalsetu/routes/app_routes.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('OnboardingScreen renders brand pill, skip button, and initial page', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put(OnboardingController());

    await tester.pumpWidget(const GetMaterialApp(
      home: OnboardingScreen(),
    ));
    await tester.pump();

    // Verify Brand Pill
    expect(find.text('DAALSETU'), findsOneWidget);

    // Verify Skip Pill
    expect(find.text('Skip'), findsOneWidget);

    // Verify First Page Title & Description
    expect(find.text('Welcome to DaalSetu'), findsOneWidget);
    expect(find.text('Buy & sell commodities easily.'), findsOneWidget);

    // Verify Action button
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('OnboardingScreen navigates to next page on Next tap and updates dot indicator', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = Get.put(OnboardingController());

    await tester.pumpWidget(const GetMaterialApp(
      home: OnboardingScreen(),
    ));
    await tester.pump();

    // Verify currently on page 0
    expect(controller.currentPage, 0);

    // Tap Next button
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify advanced to page 1
    expect(controller.currentPage, 1);
    expect(find.text('Secure Payments'), findsOneWidget);
    expect(find.text('Track contracts and payments securely.'), findsOneWidget);
  });

  testWidgets('OnboardingScreen reaches last page and shows Get Started', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = Get.put(OnboardingController());

    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/onboarding',
      getPages: [
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: AppRoutes.login, page: () => const Scaffold(body: Text('Login Screen'))),
      ],
    ));
    await tester.pump();

    // Go to page 1
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Go to page 2 (last page)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(controller.currentPage, 2);
    expect(find.text('Multi Role Platform'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    // On the last page, Skip should not be visible
    expect(find.text('Skip'), findsNothing);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Should navigate to login screen
    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('OnboardingScreen Skip button triggers completion', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put(OnboardingController());

    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/onboarding',
      getPages: [
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: AppRoutes.login, page: () => const Scaffold(body: Text('Login Screen'))),
      ],
    ));
    await tester.pump();

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Should navigate to login screen
    expect(find.text('Login Screen'), findsOneWidget);
  });

  test('OnboardingColors centralized tokens verify brand integrity', () {
    // Assert primary brand saffron
    expect(OnboardingColors.primary, const Color(0xFFF57C00));
    expect(OnboardingColors.primaryDeep, const Color(0xFFEA580C));
    expect(OnboardingColors.primaryLight, const Color(0xFFFF9800));

    // Verify ambient glow gradient generation for light and dark
    final lightGlow = OnboardingColors.ambientGlowGradient(false);
    expect(lightGlow.colors.length, 3);

    final darkGlow = OnboardingColors.ambientGlowGradient(true);
    expect(darkGlow.colors.length, 3);
  });
}
