import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/Auth/forgot_password/view/forgot_password_page.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_module_list_screen.dart';
import 'package:daalsetu/modules/dashboard/controller/dashboard_controller.dart';
import 'package:daalsetu/modules/dashboard/model/dashboard_model.dart';
import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:get/get.dart';

class _MockDashboardNavCtrl extends DashboardController {
  bool get _skipInit => true;

  @override
  void onInit() {
    if (!_skipInit) {
      super.onInit();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Bug 3: Reset Password Screen Top-Anchored Back Button', () {
    testWidgets('back arrow is top-anchored and does not float in the middle of tall screen',
        (WidgetTester tester) async {
      // Set a tall phone screen (400x900) like modern mobile devices
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the top-anchored back button
      final backButtonFinder = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.arrow_back_ios_new_rounded,
      );
      expect(backButtonFinder, findsOneWidget);

      // Verify that the back arrow is anchored at the top (< 60px from the top)
      final topLeftOffset = tester.getTopLeft(backButtonFinder);
      expect(topLeftOffset.dy, lessThan(60.0),
          reason: 'Back arrow must be anchored at the top and not float midway down the screen');
      expect(topLeftOffset.dx, lessThan(20.0),
          reason: 'Back arrow must be aligned to the top-left');

      // Verify the bottom link "Back to Sign In" still exists inside the scrollable form
      expect(find.text('Back to Sign In'), findsOneWidget);
    });
  });

  group('Bug 4: Deals in Negotiation Dashboard Route', () {
    test('adminModule route for buyer_offers resolves to expected path', () {
      final route = AppRoutes.adminModule('buyer_offers');
      expect(route, '/admin/buyer_offers');
    });

    testWidgets('tapping Deals in Negotiation card navigates directly to Buyer Offers screen',
        (WidgetTester tester) async {
      final controller = Get.put<DashboardController>(_MockDashboardNavCtrl());
      controller.isLoading.value = false;
      controller.dashboardData.value = DashboardModel.fromJson({
        'kpis': {
          'deals_in_negotiation': 2,
        },
      });

      await tester.pumpWidget(
        GetMaterialApp(
          home: AdminDashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final dealsCardFinder = find.text('Deals in Negotiation');
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(dealsCardFinder, 200, scrollable: scrollableFinder);
      expect(dealsCardFinder, findsOneWidget);

      await tester.tap(dealsCardFinder);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify that AdminModuleListScreen with buyer_offers is now displayed
      final buyerOffersScreen = find.byWidgetPredicate(
        (widget) =>
            widget is AdminModuleListScreen && widget.moduleKey == 'buyer_offers',
      );
      expect(buyerOffersScreen, findsOneWidget,
          reason: 'Tapping Deals in Negotiation must navigate directly to Buyer Offers (Negotiation Offers) screen');
    });
  });
}

