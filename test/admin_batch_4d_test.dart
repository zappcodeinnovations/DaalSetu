import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_reports/view/admin_branch_reports_view.dart';
import 'package:daalsetu/modules/admin_reports/controller/admin_reports_controller.dart';
import 'package:daalsetu/modules/admin_reports/model/branch_report_model.dart';
import 'package:daalsetu/modules/admin_reports/widgets/branch_report_card.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_branch_settings_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_brokerage_bills_screen.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineAdminReportsController extends AdminReportsController {
  @override
  Future<void> fetchReports({bool isRefresh = false, String? period}) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({
      'user_role': 'admin',
    });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AdminBranchReportsView renders HeroHeader, KPI cards, and Branch cards', (tester) async {
    final reportsCtrl = Get.put<AdminReportsController>(_OfflineAdminReportsController());
    reportsCtrl.isLoading.value = false;
    final testReport = BranchReportModel.fromJson({
      'branch_id': 1,
      'branch_name': 'Indore Central Branch',
      'branch_code': 'IND-01',
      'branch_type': 'hub',
      'is_active': true,
      'admin_name': 'Rajesh Sharma',
      'contracts_count': 42,
      'gtv_mtd': 1580000.0,
      'gtv_today': 120000.0,
      'gtv_week': 450000.0,
      'total_gtv': 2500000.0,
      'deals_count': 38,
      'offers_count': 15,
      'rfq_count': 9,
      'active_users_count': 64,
      'active_buyers_count': 30,
      'active_sellers_count': 25,
      'active_transporters_count': 9,
      'challans_count': 35,
      'otd_percent': 94,
    });
    reportsCtrl.reports.assignAll([testReport]);
    reportsCtrl.filteredReports.assignAll([testReport]);

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminBranchReportsView()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Branch Reports'), findsOneWidget);
    expect(find.text('Branch analytics, GTV & fulfillment metrics'), findsOneWidget);

    // Verify KPI & Export
    expect(find.text('Total GTV'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    // Verify Branch report card contents
    expect(find.byType(BranchReportCard), findsOneWidget);
    expect(find.text('Indore Central Branch'), findsWidgets);
  });

  testWidgets('AdminBranchSettingsScreen renders HeroHeader with drawer action', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminBranchSettingsScreen()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Branch Settings'), findsOneWidget);
    expect(find.text('Configure enterprise cross-branch permissions'), findsOneWidget);
  });

  testWidgets('AdminBrokerageBillsScreen renders HeroHeader and Create Bill action', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminBrokerageBillsScreen()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Brokerage Bills'), findsOneWidget);
    expect(find.text('Commercial brokerage settlement invoices'), findsOneWidget);

    // Verify Create Bill FAB
    expect(find.text('Create Bill'), findsOneWidget);
  });
}
