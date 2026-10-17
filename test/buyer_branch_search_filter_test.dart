import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/buyer/branch/controller/buyer_branch_controller.dart';
import 'package:daalsetu/modules/seller/branches/model/seller_branch_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BuyerBranchController Search & Filter Tests', () {
    late BuyerBranchController controller;

    setUp(() {
      Get.reset();
      controller = BuyerBranchController();

      // Seed Primary Branch
      controller.primaryBranch.value = SellerBranchModel(
        id: 1,
        branchCode: "AMA462M",
        locationName: "Amalner Main",
        city: "Amalner",
        state: "Maharashtra",
        area: "Amravati Region",
        adminName: "Pradeep H Jhawar",
        userName: "Harman Singh",
        isPrimary: true,
      );

      // Seed Connected / Additional Branches
      controller.myBranches.assignAll([
        SellerBranchModel(
          id: 2,
          branchCode: "NAG821M",
          locationName: "Nagpur Central",
          city: "Nagpur",
          state: "Maharashtra",
          area: "Sitabuldi",
          adminName: "Rajesh Sharma",
          userName: "Test Buyer",
          isPrimary: false,
        ),
        SellerBranchModel(
          id: 3,
          branchCode: "IND901M",
          locationName: "Indore Mandi",
          city: "Indore",
          state: "Madhya Pradesh",
          area: "Chhavani",
          adminName: "Anil Patel",
          userName: "Test Buyer",
          isPrimary: false,
        ),
      ]);

      // Seed Pending Join Requests
      controller.pendingRequests.assignAll([
        SellerBranchModel(
          id: 4,
          branchCode: "PUN550M",
          locationName: "Pune Hub",
          city: "Pune",
          state: "Maharashtra",
          area: "Hadapsar",
          adminName: "Vikram Kulkarni",
          status: "pending",
        ),
      ]);
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('Initial state displays all branches unfiltered', () {
      expect(controller.filteredPrimaryBranch, isNotNull);
      expect(controller.filteredPrimaryBranch!.branchCode, "AMA462M");
      expect(controller.filteredMyBranches.length, 2);
      expect(controller.filteredPendingRequests.length, 1);
      expect(controller.hasFilteredResults, true);
    });

    test('Filters by branch code (case-insensitive)', () {
      controller.setSearchQuery("nag821m");

      expect(controller.filteredPrimaryBranch, isNull);
      expect(controller.filteredMyBranches.length, 1);
      expect(controller.filteredMyBranches.first.branchCode, "NAG821M");
      expect(controller.filteredPendingRequests.length, 0);
    });

    test('Filters by city / state / area', () {
      // By city
      controller.setSearchQuery("Indore");
      expect(controller.filteredMyBranches.length, 1);
      expect(controller.filteredMyBranches.first.city, "Indore");

      // By area
      controller.setSearchQuery("Sitabuldi");
      expect(controller.filteredMyBranches.length, 1);
      expect(controller.filteredMyBranches.first.branchCode, "NAG821M");

      // By state
      controller.setSearchQuery("Madhya Pradesh");
      expect(controller.filteredPrimaryBranch, isNull);
      expect(controller.filteredMyBranches.length, 1);
      expect(controller.filteredMyBranches.first.city, "Indore");
    });

    test('Filters by admin name or user name', () {
      // By admin
      controller.setSearchQuery("Pradeep");
      expect(controller.filteredPrimaryBranch, isNotNull);
      expect(controller.filteredPrimaryBranch!.adminName, "Pradeep H Jhawar");
      expect(controller.filteredMyBranches.isEmpty, true);

      // By user
      controller.setSearchQuery("Harman");
      expect(controller.filteredPrimaryBranch, isNotNull);
      expect(controller.filteredMyBranches.isEmpty, true);
    });

    test('Filters by branch type chip', () {
      // Primary only
      controller.setTypeFilter("primary");
      expect(controller.filteredPrimaryBranch, isNotNull);
      expect(controller.filteredMyBranches.isEmpty, true);
      expect(controller.filteredPendingRequests.isEmpty, true);

      // Additional only
      controller.setTypeFilter("additional");
      expect(controller.filteredPrimaryBranch, isNull);
      expect(controller.filteredMyBranches.length, 2);
      expect(controller.filteredPendingRequests.isEmpty, true);

      // Pending only
      controller.setTypeFilter("pending");
      expect(controller.filteredPrimaryBranch, isNull);
      expect(controller.filteredMyBranches.isEmpty, true);
      expect(controller.filteredPendingRequests.length, 1);
      expect(controller.filteredPendingRequests.first.branchCode, "PUN550M");
    });

    test('Reset filter clears search input and restores full list', () {
      controller.setSearchQuery("NAG821M");
      controller.setTypeFilter("additional");
      expect(controller.isFilterActive, true);
      expect(controller.filteredMyBranches.length, 1);

      controller.resetFilter();
      expect(controller.isFilterActive, false);
      expect(controller.searchQuery.value, "");
      expect(controller.selectedTypeFilter.value, "all");
      expect(controller.filteredPrimaryBranch, isNotNull);
      expect(controller.filteredMyBranches.length, 2);
      expect(controller.filteredPendingRequests.length, 1);
    });
  });
}
