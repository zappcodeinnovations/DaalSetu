import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/seller/branches/view/seller_branches_view.dart';
import 'package:daalsetu/modules/seller/branches/controller/seller_branch_controller.dart';
import 'package:daalsetu/modules/seller/masters/view/seller_master_management_view.dart';
import 'package:daalsetu/modules/seller/masters/controller/seller_master_controller.dart';
import 'package:daalsetu/modules/seller/products/view/offer_stock_history_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SellerBranchesView renders HeroHeader and Join Existing Branch banner', (tester) async {
    final controller = Get.put(SellerBranchController());
    controller.isLoading.value = false;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SellerBranchesView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("My Branches"), findsOneWidget);
    expect(find.text("Join Existing Branch"), findsOneWidget);
    expect(find.text("JOIN CODE"), findsOneWidget);
  });

  testWidgets('SellerMasterManagementView renders HeroHeader with TabBar and Add FAB', (tester) async {
    final controller = Get.put(SellerMasterController());
    controller.isLoading.value = false;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SellerMasterManagementView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Master Data"), findsOneWidget);
    expect(find.text("Brands"), findsOneWidget);
    expect(find.text("Quality Tags"), findsOneWidget);
    expect(find.text("Add"), findsOneWidget);
  });

  testWidgets('OfferStockHistoryView renders HeroHeader and summary card cleanly', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OfferStockHistoryView(productId: 1, title: 'Chana Desi Medium'),
      ),
    );
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Stock History"), findsOneWidget);
  });
}
