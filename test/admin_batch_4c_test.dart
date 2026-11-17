import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_dc/view/admin_dc_list_view.dart';
import 'package:daalsetu/modules/admin_dc/controller/admin_dc_list_controller.dart';
import 'package:daalsetu/modules/admin_dc/view/admin_create_dc_view.dart';
import 'package:daalsetu/modules/admin_dc/controller/admin_create_dc_controller.dart';
import 'package:daalsetu/modules/admin_dc/view/admin_dc_details_view.dart';
import 'package:daalsetu/modules/admin_dc/controller/admin_dc_details_controller.dart';
import 'package:daalsetu/modules/admin_dc/model/admin_challan_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineAdminDCListController extends AdminDCListController {
  @override
  Future<void> fetchChallans({bool isRefresh = false}) async {}
}

class _OfflineAdminCreateDCController extends AdminCreateDCController {
  @override
  Future<void> fetchContracts({bool isRefresh = false}) async {}
}

class _OfflineAdminDCDetailsController extends AdminDCDetailsController {
  @override
  Future<void> fetchDetails(int id, {bool isRefresh = false}) async {}
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

  testWidgets('AdminChallanListView renders HeroHeader, KPI cards, and Challan cards', (tester) async {
    final listCtrl = Get.put<AdminDCListController>(_OfflineAdminDCListController());
    listCtrl.isLoading.value = false;
    final testChallan = AdminChallanModel.fromJson({
      'id': 201,
      'challan_number': 'DC-2026-001',
      'status': 'dispatched',
      'seller_name': 'Maha Daal Mills',
      'buyer_name': 'Agro Traders Ltd',
      'truck_number': 'MH-12-AB-1234',
      'driver_name': 'Ramesh Kumar',
      'commodity_name': 'Toor Daal Premium',
      'quantity': '200',
      'quantity_unit': 'Qtl',
    });
    listCtrl.challans.assignAll([testChallan]);
    listCtrl.filteredChallans.assignAll([testChallan]);

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminChallanListView()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Delivery Challans'), findsOneWidget);
    expect(find.text('Freight dispatch tracking & documentation'), findsOneWidget);

    // Verify KPI and FAB
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Create DC'), findsOneWidget);

    // Verify Challan card contents
    expect(find.text('DC-2026-001'), findsOneWidget);
  });

  testWidgets('AdminCreateChallanView renders HeroHeader and section cards', (tester) async {
    Get.put<AdminCreateDCController>(_OfflineAdminCreateDCController());

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminCreateChallanView()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Create Delivery Challan'), findsOneWidget);
    expect(find.text('Generate official dispatch note from contract'), findsOneWidget);

    // Verify Sections and Submit CTA
    expect(find.text('1. Select Confirmed Deal'), findsOneWidget);
    expect(find.text('Generate Delivery Challan'), findsOneWidget);
  });

  testWidgets('AdminChallanDetailsView renders HeroHeader and Challan details slip', (tester) async {
    final detailsCtrl = Get.put<AdminDCDetailsController>(_OfflineAdminDCDetailsController());
    detailsCtrl.isLoading.value = false;
    final testChallan = AdminChallanModel.fromJson({
      'id': 201,
      'challan_number': 'DC-2026-001',
      'status': 'dispatched',
      'seller_name': 'Maha Daal Mills',
      'buyer_name': 'Agro Traders Ltd',
      'truck_number': 'MH-12-AB-1234',
      'driver_name': 'Ramesh Kumar',
      'commodity_name': 'Toor Daal Premium',
      'quantity': '200',
      'quantity_unit': 'Qtl',
    });
    detailsCtrl.challan.value = testChallan;

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminChallanDetailsView()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Delivery Challan Slip'), findsOneWidget);
    expect(find.text('Consignment dispatch tracking & documentation'), findsOneWidget);

    // Verify Status Banner and Challan information
    expect(find.text('STATUS: DISPATCHED'), findsOneWidget);
  });
}
