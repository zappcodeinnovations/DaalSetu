import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/buyer/branch/controller/buyer_branch_controller.dart';
import 'package:daalsetu/modules/buyer/branch/view/buyer_branch_view.dart';
import 'package:daalsetu/modules/seller/branches/model/seller_branch_model.dart';

class TestBuyerBranchController extends BuyerBranchController {
  @override
  void onInit() {
    // Skip network calls in widget tests
  }

  @override
  Future<void> fetchBranches({bool silent = false}) async {
    // Skip network calls in widget tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BuyerBranchView Filter Actions & Badges Tests', () {
    late TestBuyerBranchController controller;

    setUp(() {
      Get.reset();
      controller = Get.put<BuyerBranchController>(TestBuyerBranchController()) as TestBuyerBranchController;

      // Seed Primary Branch
      controller.primaryBranch.value = SellerBranchModel(
        id: 1,
        branchCode: "AMA462M",
        locationName: "Amalner Main",
        city: "Amalner",
        state: "Maharashtra",
        isPrimary: true,
      );

      // Seed Additional Branch
      controller.myBranches.assignAll([
        SellerBranchModel(
          id: 2,
          branchCode: "NAG821M",
          locationName: "Test Branch",
          city: "Nagpur",
          state: "Maharashtra",
          isPrimary: false,
        ),
      ]);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Search card has no redundant Clear link, retains Apply and Reset buttons', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: BuyerBranchView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Check "Search" label exists
      expect(find.text("Search"), findsOneWidget);

      // Verify "Clear" text link in header does NOT exist
      expect(find.text("Clear"), findsNothing);

      // Verify "Apply" and "Reset" buttons exist
      expect(find.text("Apply"), findsOneWidget);
      expect(find.text("Reset"), findsOneWidget);
    });

    testWidgets('Branch cards render Primary and Additional badges and Leave button', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: BuyerBranchView(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify "Primary" appears in both the filter chip and the Primary Branch card badge
      expect(find.text("Primary"), findsNWidgets(2));

      // Verify "Additional" appears in both the filter chip and the Test Branch card badge
      expect(find.text("Additional"), findsNWidgets(2));

      // Verify "LEAVE" button exists for the additional branch
      expect(find.text("LEAVE"), findsOneWidget);
    });
  });
}
