import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/seller/challans/view/seller_delivery_challan_view.dart';
import 'package:daalsetu/modules/seller/challans/controller/seller_challan_controller.dart';
import 'package:daalsetu/modules/seller/consignments/view/seller_consignments_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SellerDeliveryChallanView renders HeroHeader and empty state cleanly', (tester) async {
    final controller = Get.put(SellerChallanController());
    controller.isLoading.value = false;
    controller.challansList.clear();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SellerDeliveryChallanView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Delivery Challans"), findsOneWidget);
    expect(find.text("Dispatched shipments & transit tracking"), findsOneWidget);
    expect(find.text("No Delivery Challans Found"), findsOneWidget);
  });

  testWidgets('SellerConsignmentsView renders HeroHeader, search bar, and filter chips', (tester) async {
    final controller = Get.put(SellerConsignmentController());
    controller.isLoading.value = false;
    controller.rows.clear();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SellerConsignmentsView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Consignments"), findsOneWidget);
    expect(find.text("Stock consignments & warehouse dispatch tracking"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text("All"), findsOneWidget);
    expect(find.text("Pending"), findsOneWidget);
    expect(find.text("Ready"), findsOneWidget);
    expect(find.text("Dispatched"), findsOneWidget);
    expect(find.text("Received"), findsOneWidget);
  });
}
