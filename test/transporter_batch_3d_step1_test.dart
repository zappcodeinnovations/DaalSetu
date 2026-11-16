import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/brands/view/transporter_brands_view.dart';
import 'package:daalsetu/modules/transporter/brands/controller/transporter_brands_controller.dart';
import 'package:daalsetu/modules/transporter/brands/model/transporter_brand_model.dart';
import 'package:daalsetu/modules/transporter/categories/view/transporter_category_view.dart';
import 'package:daalsetu/modules/seller/categories/controller/seller_category_controller.dart';
import 'package:daalsetu/modules/seller/categories/model/seller_category_model.dart';
import 'package:daalsetu/modules/seller/categories/model/category_dashboard_model.dart';
import 'package:daalsetu/modules/transporter/products/view/transporter_products_view.dart';
import 'package:daalsetu/modules/products/controller/product_controller.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineBrandsController extends TransporterBrandsController {
  @override
  Future<void> refreshAll() async {}
  @override
  Future<void> fetchBrandsList() async {}
  @override
  Future<void> fetchBrandsDashboard() async {}
}

class _OfflineCategoryController extends SellerCategoryController {
  @override
  Future<void> fetchAllData() async {}
  @override
  Future<void> fetchBrands() async {}
}

class _OfflineProductController extends ProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('TransporterBrandsView renders HeroHeader, Overview KPIs, and Brand cards', (tester) async {
    final brandsCtrl = Get.put<TransporterBrandsController>(_OfflineBrandsController());
    brandsCtrl.isLoading.value = false;
    brandsCtrl.dashboardData.value = TransporterBrandDashboardData(
      totalBrands: 15,
      activeBrands: 12,
      brandsInUse: 8,
    );
    brandsCtrl.brandsList.assignAll([
      TransporterBrandModel(
        id: 1,
        name: "Shree Daal Brand",
        companyName: "Shree Mills Pvt Ltd",
        description: "Premium toor daal processor",
        isActive: true,
      ),
    ]);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: TransporterBrandsView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Brands'), findsOneWidget);
    expect(find.text('Registered brands & catalog directory'), findsOneWidget);

    // Verify KPIs
    expect(find.text('Overview & Status'), findsOneWidget);
    expect(find.text('Total Brands'), findsOneWidget);
    expect(find.text('Active Brands'), findsOneWidget);
    expect(find.text('Brands in Use'), findsOneWidget);

    // Verify Search & Brand Card
    expect(find.text('Search brands by name...'), findsOneWidget);
    expect(find.text('Shree Daal Brand'), findsOneWidget);
    expect(find.text('Shree Mills Pvt Ltd'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('TransporterCategoryView renders HeroHeader, Overview, and Category nodes', (tester) async {
    final categoryCtrl = Get.put<SellerCategoryController>(_OfflineCategoryController());
    categoryCtrl.isLoading.value = false;
    categoryCtrl.dashboardData.value = CategoryDashboardModel(
      total: 24,
      root: 6,
      active: 20,
      pending: 4,
      sub: 18,
    );
    categoryCtrl.categoryTree.assignAll([
      CategoryTreeModel(
        id: 1,
        name: "Pulses & Legumes",
        level: 0,
        status: "active",
        childrenCount: 3,
        hasChildren: true,
        brands: [],
        children: [
          CategoryTreeModel(
            id: 2,
            name: "Toor Daal",
            level: 1,
            status: "active",
            childrenCount: 0,
            hasChildren: false,
            brands: [],
            children: [],
          ),
        ],
      ),
    ]);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterCategoryView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Agricultural commodity taxonomy'), findsOneWidget);

    // Verify Dashboard Overview
    expect(find.text('Category Overview'), findsOneWidget);
    expect(find.text('Total Categories'), findsOneWidget);
    expect(find.text('Root'), findsOneWidget);
    expect(find.text('Sub Categories'), findsOneWidget);

    // Verify Category Tree Node
    expect(find.text('Pulses & Legumes'), findsOneWidget);
    expect(find.text('3 Subcategories'), findsOneWidget);
  });

  testWidgets('TransporterProductsView renders HeroHeader and Commodity Product cards', (tester) async {
    final productCtrl = Get.put<ProductController>(_OfflineProductController());
    final mockProduct = ProductModel.fromJson({
      'id': 101,
      'title': 'Desi Chana Bold Grade A',
      'description': 'High protein clean desi chana',
      'category': {'id': 1, 'name': 'Chana', 'slug': 'chana'},
      'amount': '5500.00',
      'amount_unit': 'Qtl',
      'available_quantity': '150',
      'quantity_unit': 'Qtl',
      'is_active': true,
      'status': 'active',
      'deal_status': 'active',
    });
    productCtrl.products.assignAll([mockProduct]);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterProductsView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Commodity Products'), findsOneWidget);
    expect(find.text('Products listed in network catalog'), findsOneWidget);

    // Verify Product Card
    expect(find.text('Desi Chana Bold Grade A'), findsOneWidget);
    expect(find.text('Chana'), findsOneWidget);
    expect(find.text('₹5500.00/Qtl'), findsOneWidget);
    expect(find.text('150 Qtl'), findsOneWidget);
  });
}
