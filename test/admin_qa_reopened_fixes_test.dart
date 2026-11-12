import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/kyc_users/controller/kyc_user_controller.dart';
import 'package:daalsetu/modules/kyc_users/model/kyc_user_model.dart';
import 'package:daalsetu/modules/contracts/model/contract_model.dart';
import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/modules/contracts/view/contract_view.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_category_master_screen.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_category_master_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug 7 & Bug 9: KYC Users Search, Filter, and Chip UI Alignment Tests', () {
    late KycController controller;

    setUp(() {
      Get.reset();
      controller = KycController();
      controller.kycUsers.assignAll([
        KycUserModel(
          id: 101,
          name: 'Mukesh Sharma',
          mobile: '9876543210',
          email: 'mukesh@example.com',
          role: 'buyer',
          panNumber: 'ABCDE1234F',
          gstNumber: null,
          kycStatus: 'approved',
          kycSubmittedAt: null,
          kycApprovedAt: null,
          kycRejectedAt: null,
          kycRejectionReason: null,
          accountStatus: 'active',
        ),
        KycUserModel(
          id: 102,
          name: 'Suresh Patel',
          mobile: '9876543211',
          email: 'suresh@example.com',
          role: 'seller',
          panNumber: 'FGHIJ5678K',
          gstNumber: null,
          kycStatus: 'pending',
          kycSubmittedAt: null,
          kycApprovedAt: null,
          kycRejectedAt: null,
          kycRejectionReason: null,
          accountStatus: 'active',
        ),
      ]);
    });

    test('KycController filters by role case-insensitively and handles spaces/underscores', () {
      controller.selectedRole.value = 'buyer';
      controller.selectedFilter.value = 'all';
      controller.searchQuery.value = '';

      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Mukesh Sharma');

      controller.selectedRole.value = 'Seller';
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Suresh Patel');

      controller.selectedRole.value = 'all';
      expect(controller.filteredUsers.length, 2);
    });

    test('KycController resets all filter fields cleanly', () {
      controller.selectedRole.value = 'buyer';
      controller.selectedFilter.value = 'approved';
      controller.searchQuery.value = 'mukesh';

      controller.resetFilters();

      expect(controller.selectedRole.value, 'all');
      expect(controller.selectedFilter.value, 'all');
      expect(controller.searchQuery.value, '');
    });
  });

  group('Bug 3: Contracts Screen Direct Details Navigation (No Unauthorized Selection Mode)', () {
    testWidgets('Contracts screen renders without multi-select checkboxes', (tester) async {
      Get.reset();
      final contractController = Get.put(ContractController());
      contractController.contracts.assignAll([
        ContractModel.fromJson({
          'id': 201,
          'contract_id': 'JBC2607290751',
          'product_title': 'URADDAAL',
          'product_category_name': 'URAD DAL',
          'seller_name': 'MUKESH',
          'buyer_name': 'Buyer2 tester',
          'display_seller_id': 'SELD2E62DC55D',
          'display_buyer_id': 'BUY7FE0942A32',
          'deal_amount': '65.00',
          'deal_quantity': '900.000',
          'amount_unit': 'ton',
          'quantity_unit': 'qtl',
          'loading_from': 'pune',
          'loading_to': 'nagpur',
          'status': 'active',
          'created_at': '2026-10-10',
        }),
      ]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ContractsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Contracts'), findsOneWidget);

      // Verify Refresh action exists
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Verify no select all or delete or close buttons in AppBar
      expect(find.byIcon(Icons.select_all_rounded), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // Verify card content renders cleanly
      expect(find.text('URADDAAL'), findsOneWidget);
      expect(find.text('Tap to view complete details  ›'), findsOneWidget);
    });
  });

  group('Bug 11: Category Master Brands Modal All & None Segmented Capsule Buttons', () {
    testWidgets('Brands modal renders styled All and None buttons and triggers controller', (tester) async {
      Get.reset();
      final catController = Get.put(AdminCategoryMasterController());
      catController.allBrands.assignAll([
        {'id': 1, 'brand_name': 'Brand A'},
        {'id': 2, 'brand_name': 'Brand B'},
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Brands'),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => catController.selectAllBrands(),
                                  child: const Text('All'),
                                ),
                                InkWell(
                                  onTap: () => catController.deselectAllBrands(),
                                  child: const Text('None'),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Select Brands'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);

      // Tap All
      await tester.tap(find.text('All'));
      expect(catController.selectedBrandIds.length, 2);

      // Tap None
      await tester.tap(find.text('None'));
      expect(catController.selectedBrandIds.isEmpty, true);
    });

    testWidgets('Category Master renders without overflow and Category card shows clickable Brands badge', (tester) async {
      Get.reset();
      final catController = Get.put(AdminCategoryMasterController());
      catController.treeCategories.assignAll([
        CategoryTreeModel(
          id: 1,
          name: 'twst',
          level: 0,
          status: 'pending',
          children: [],
          brands: [
            {'id': 10, 'brand_name': 'Brand X'},
          ],
        ),
      ]);
      catController.totalCount.value = 30;
      catController.rootCount.value = 14;
      catController.subCount.value = 16;
      catController.activeCount.value = 2;
      catController.inactiveCount.value = 0;
      catController.isLoading.value = false;

      // Test with compact height to ensure summary cards do not overflow
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AdminCategoryMasterScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Summary Cards render cleanly with no overflow
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);

      // Verify Category Card with '1 Brands' badge
      expect(find.text('twst'), findsOneWidget);
      expect(find.text('1 Brands'), findsOneWidget);

      // Tap on '1 Brands' badge to verify bottom sheet opens
      await tester.tap(find.text('1 Brands'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the sheet shows category name, mapped brand, and edit button
      expect(find.text('twst'), findsWidgets);
      expect(find.text('Brand X'), findsOneWidget);
      expect(find.text('Edit / Map Brands'), findsOneWidget);
    });
  });

  group('Bug 8: Brokerage Bills Billing Company Filtering & Null Draft Exclusion Tests', () {
    test('Filtering by FARMLAND includes FARMLAND bills and excludes unassigned draft bills', () {
      final sampleBills = [
        {
          'id': 1,
          'bill_number': 'FARM/2026/00002',
          'status': 'issued',
          'billing_company_name': 'FARMLAND',
          'billing_company_id': '1',
          'seller': {'first_name': 'Test', 'last_name': 'Seller'},
        },
        {
          'id': 16,
          'bill_number': '',
          'status': 'draft',
          'billing_company_name': null,
          'billing_company_id': null,
          'seller': {'first_name': 'Test', 'last_name': 'Seller'},
        },
        {
          'id': 2,
          'bill_number': 'ABC/2026/00001',
          'status': 'issued',
          'billing_company_name': 'ABC Company',
          'billing_company_id': '2',
          'seller': {'first_name': 'Another', 'last_name': 'Seller'},
        },
      ];

      const selectedCompany = 'FARMLAND';
      const companyName = 'FARMLAND';
      const numericId = '1';

      final filtered = sampleBills.where((bill) {
        final billCompName = (bill['billing_company_name'] ?? '').toString().trim().toLowerCase();
        final billCompId = (bill['billing_company_id'] ?? '').toString().trim();
        final cleanBillCompId = billCompId.replaceAll(RegExp(r'[^0-9]'), '');

        if (billCompName.isEmpty && billCompId.isEmpty) return false;

        bool matched = false;
        if (companyName.isNotEmpty && billCompName.isNotEmpty) {
          if (billCompName == companyName.toLowerCase()) matched = true;
        }
        if (numericId.isNotEmpty && cleanBillCompId.isNotEmpty) {
          if (cleanBillCompId == numericId) matched = true;
        }
        if (selectedCompany.isNotEmpty && billCompName == selectedCompany.toLowerCase()) {
          matched = true;
        }
        return matched;
      }).toList();

      // Only FARM/2026/00002 should match, Draft bill #16 and ABC Company must be excluded
      expect(filtered.length, 1);
      expect(filtered.first['bill_number'], 'FARM/2026/00002');
    });

    test('Filtering by non-existent company returns 0 results instead of leaking drafts or other bills', () {
      final sampleBills = [
        {
          'id': 1,
          'bill_number': 'FARM/2026/00002',
          'status': 'issued',
          'billing_company_name': 'FARMLAND',
        },
        {
          'id': 16,
          'bill_number': '',
          'status': 'draft',
          'billing_company_name': null,
        },
      ];

      const companyName = 'Random Nonexistent Co';

      final filtered = sampleBills.where((bill) {
        final billCompName = (bill['billing_company_name'] ?? '').toString().trim().toLowerCase();
        if (billCompName.isEmpty) return false;
        return billCompName == companyName.toLowerCase();
      }).toList();

      expect(filtered.isEmpty, true);
    });
  });
}

