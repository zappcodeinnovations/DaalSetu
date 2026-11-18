import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daalsetu/modules/nav_bar/view/nav_page.dart';
import 'package:daalsetu/modules/buyer/dashboard/model/buyer_dashboard_model.dart';
import 'package:daalsetu/modules/buyer/dashboard/view/buyer_dashboard_view.dart';
import 'package:daalsetu/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart';
import 'package:daalsetu/modules/settings/view/settings_page.dart';
import 'package:daalsetu/theme/theme_controller.dart';
import 'package:daalsetu/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return 'buyer';
        }
        return null;
      },
    );
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put(ThemeController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Buyer GlassNavBar renders exactly 5 tabs and shows full Dashboard label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(376, 799);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    int tappedIndex = -1;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          bottomNavigationBar: GlassNavBar(
            currentIndex: 0,
            role: 'buyer',
            onTap: (index) => tappedIndex = index,
          ),
          body: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify exactly 5 tabs are present in the buyer navigation bar
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Challan'), findsOneWidget);
    expect(find.text('Branch'), findsOneWidget);

    // Settings must no longer be in the bottom bar
    final settingsInNavBar = find.descendant(
      of: find.byKey(const Key('floating_glass_nav_bar_container')),
      matching: find.text('Settings'),
    );
    expect(settingsInNavBar, findsNothing);

    // Tap on Products tab
    await tester.tap(find.text('Products'));
    expect(tappedIndex, equals(1));
  });

  testWidgets('Buyer Dashboard Header renders Settings icon beside Notification Bell and navigates to SettingsScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(376, 799);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = Get.put(BuyerDashboardController(
      dashboardLoader: ({range}) async => <String, dynamic>{
        'kpis': <String, dynamic>{},
        'charts': <String, dynamic>{},
        'recent_rfqs': <dynamic>[],
        'recent_orders': <dynamic>[],
        'transport_tracking': <dynamic>[],
      },
      categoryLoader: () async => [],
      offersLoader: () async => [],
    ));
    await controller.fetchDashboardData();

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: BuyerDashboardView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Settings icon is present in the top header
    final settingsIconFinder = find.byTooltip('Settings');
    expect(settingsIconFinder, findsOneWidget);

    // Notification icon is also present
    expect(find.byIcon(IconlyLight.notification), findsOneWidget);

    // Tap Settings icon and verify navigation
    await tester.tap(settingsIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
