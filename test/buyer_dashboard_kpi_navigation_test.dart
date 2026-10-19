import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daalsetu/modules/buyer/dashboard/view/buyer_dashboard_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart';
import 'package:daalsetu/modules/profile/controller/profile_controller.dart';

class MockBuyerDashboardController extends BuyerDashboardController {
  @override
  Future<void> fetchDashboardData({String? range}) async {}
}

class MockProfileController extends ProfileController {}

class MockBuyerOffersController extends BuyerOffersController {
  MockBuyerOffersController({required super.offerType});

  @override
  Future<void> fetchOffers({bool isRefresh = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put<BuyerDashboardController>(MockBuyerDashboardController());
    Get.put<ProfileController>(MockProfileController());
    for (final tag in ['all', 'today', 'pending', 'previous']) {
      Get.put<BuyerOffersController>(
        MockBuyerOffersController(offerType: tag),
        tag: tag,
      );
    }
  });

  tearDown(() {
    Get.reset();
  });

  final sampleKpis = <String, dynamic>{
    'spent_mtd': '247860.00',
    'active_orders': '4',
    'open_requirements': '0',
    'active_contracts': '5',
    'signed_this_month': '0',
    'in_transit': '0',
    'avg_eta': '—',
    'pay_pending': 'Not tracked',
    'pending_amount': 'Not tracked',
    'issues': 'Not tracked',
    'open_tickets': 'Not tracked',
    'top_supplier': '1234567890',
    'top_supplier_share': '100.0% of spend',
    'avg_purchase_price': '260.00',
    'avg_price_delta': '—',
  };

  testWidgets('Tapping TOP SUPPLIER (MTD) navigates to BuyerOffersView', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) => BuyerDashboardView().buildKPIGrid(context, sampleKpis),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify TOP SUPPLIER (MTD) card is present
    final topSupplierFinder = find.text('TOP SUPPLIER (MTD)');
    expect(topSupplierFinder, findsOneWidget);

    // Tap the TOP SUPPLIER card
    await tester.tap(topSupplierFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify it navigated to BuyerOffersView
    expect(find.byType(BuyerOffersView), findsOneWidget);
    expect(find.text('Offers & Requirements'), findsOneWidget);
  });

  testWidgets('Tapping AVG PURCHASE PRICE navigates to BuyerOffersView', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) => BuyerDashboardView().buildKPIGrid(context, sampleKpis),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify AVG PURCHASE PRICE card is present
    final avgPriceFinder = find.text('AVG PURCHASE PRICE');
    expect(avgPriceFinder, findsOneWidget);

    // Tap the AVG PURCHASE PRICE card
    await tester.tap(avgPriceFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify it navigated to BuyerOffersView
    expect(find.byType(BuyerOffersView), findsOneWidget);
    expect(find.text('Offers & Requirements'), findsOneWidget);
  });

  testWidgets('AVG PURCHASE PRICE prefers the web dashboard avg_price field', (
    tester,
  ) async {
    final kpis = <String, dynamic>{
      ...sampleKpis,
      'avg_purchase_price': '200.00',
      'avg_price': '₹260.00/qtl',
    };
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Builder(
              builder: (context) =>
                  BuyerDashboardView().buildKPIGrid(context, kpis),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('₹260.00/qtl'), findsOneWidget);
    expect(find.text('₹200.00/qtl'), findsNothing);
  });
}
