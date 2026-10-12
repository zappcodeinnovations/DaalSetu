import 'package:daalsetu/modules/splashscreen/view/splash_screen.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashScreen renders logo with BoxFit.contain inside SafeArea',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.onboarding: (_) => const Scaffold(body: Text('Onboarding Screen')),
          AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
        },
        home: const SplashScreen(),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify SafeArea exists for safe layout boundaries
    expect(find.byType(SafeArea), findsOneWidget);

    // Verify the logo image is present and uses BoxFit.contain
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.fit, BoxFit.contain);
    expect((imageWidget.image as AssetImage).assetName,
        'assets/images/app_icon.jpeg');

    // Verify branding text
    expect(find.text('Cultivating Connections'), findsOneWidget);

    // Advance through the delayed animations and navigation
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(seconds: 3));

    // Navigated to Onboarding Screen, which disposes SplashScreen and stops ring ticker
    await tester.pump();
    expect(find.text('Onboarding Screen'), findsOneWidget);
  });
}
