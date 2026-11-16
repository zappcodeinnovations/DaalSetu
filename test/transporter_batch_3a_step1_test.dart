import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/bidding/view/transporter_bidding_view.dart';
import 'package:daalsetu/modules/transporter/bidding/controller/transporter_bidding_controller.dart';
import 'package:daalsetu/modules/transporter/dashboard/view/transporter_dashboard_view.dart';
import 'package:daalsetu/modules/transporter/company/controller/transporter_company_controller.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineCompanyController extends TransporterCompanyController {
  @override
  Future<void> fetchCompanies() async {}
}

class _OfflineBiddingController extends TransporterBiddingController {
  @override
  Future<void> fetchOpenOffers() async {}

  @override
  Future<void> fetchMyBids() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('TransporterDashboardView renders HeroHeader and KPI sections', (tester) async {
    Get.put<TransporterCompanyController>(_OfflineCompanyController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: TransporterDashboardView()));
    await tester.pump();

    // Verify HeroHeader presence
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
  });

  testWidgets('TransporterBiddingView renders HeroHeader with tabs', (tester) async {
    Get.put<TransporterBiddingController>(_OfflineBiddingController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterBiddingView()));
    await tester.pump();

    // Verify HeroHeader presence
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Active Shipment Offers'), findsOneWidget);
    expect(find.text('My Deals'), findsOneWidget);
  });
}
