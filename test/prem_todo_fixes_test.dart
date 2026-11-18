import 'package:daalsetu/modules/seller/challans/controller/seller_challan_controller.dart';
import 'package:daalsetu/modules/seller/challans/model/seller_challan_model.dart';
import 'package:daalsetu/modules/seller/challans/view/seller_delivery_challan_view.dart';
import 'package:daalsetu/modules/seller/dashboard/view/seller_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeChallanController extends SellerChallanController {
  @override
  void onInit() {
    challansList.assignAll([
      SellerChallanModel(id: 1, challanNumber: 'CH-TRANSIT-1', status: 'dispatched'),
      SellerChallanModel(id: 2, challanNumber: 'CH-DONE-2', status: 'delivered'),
      SellerChallanModel(id: 3, challanNumber: 'CH-DRAFT-3', status: 'draft'),
    ]);
  }

  @override
  Future<void> fetchChallans() async {}
}

void main() {
  tearDown(Get.reset);

  test('pipeline counts show as whole numbers, never "4.0"', () {
    expect(SellerDashboardView.countText(4.0), '4');
    expect(SellerDashboardView.countText('4.0'), '4');
    expect(SellerDashboardView.countText(3), '3');
    expect(SellerDashboardView.countText(null), '0');
  });

  testWidgets('In Transit KPI opens only the dispatched challans', (tester) async {
    Get.put<SellerChallanController>(_FakeChallanController());
    await tester.pumpWidget(
      const GetMaterialApp(home: SellerDeliveryChallanView(statusFilter: 'dispatched')),
    );
    await tester.pump();

    expect(find.text('In Transit'), findsWidgets);
    expect(find.textContaining('CH-TRANSIT-1'), findsWidgets);
    expect(find.textContaining('CH-DONE-2'), findsNothing);
    expect(find.textContaining('CH-DRAFT-3'), findsNothing);
  });

  testWidgets('the plain challans screen still lists every status', (tester) async {
    Get.put<SellerChallanController>(_FakeChallanController());
    await tester.pumpWidget(const GetMaterialApp(home: SellerDeliveryChallanView()));
    await tester.pump();

    expect(find.textContaining('CH-TRANSIT-1'), findsWidgets);
    expect(find.textContaining('CH-DONE-2'), findsWidgets);
  });
}
