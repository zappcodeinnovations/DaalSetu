import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_catalog/view/admin_offers_list_screen.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_offers_controller.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_category_master_screen.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_category_master_controller.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_detail_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineAdminOffersController extends AdminOffersController {
  @override
  Future<void> fetchOffers({bool silent = false}) async {}
}

class _OfflineAdminCategoryMasterController extends AdminCategoryMasterController {
  @override
  Future<void> fetchData() async {}
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

  testWidgets('AdminOffersListScreen renders HeroHeader and modernized offer cards', (tester) async {
    final offersCtrl = Get.put<AdminOffersController>(_OfflineAdminOffersController());
    offersCtrl.isLoading.value = false;
    offersCtrl.offers.assignAll([
      ProductModel.fromJson({
        'id': 101,
        'title': 'Premium Chana Daal',
        'amount': '78.50',
        'available_quantity': '500',
        'images': [],
        'videos': [],
      }),
    ]);

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminOffersListScreen()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Admin Offers'), findsOneWidget);
    expect(find.text('Live commodity trading offers & deal approvals'), findsOneWidget);

    // Verify Offer Card
    expect(find.byKey(const Key('admin_offer_card_101')), findsOneWidget);
    expect(find.text('Premium Chana Daal'), findsOneWidget);
  });

  testWidgets('AdminCategoryMasterScreen renders HeroHeader, stats pods and Add Category button', (tester) async {
    final catCtrl = Get.put<AdminCategoryMasterController>(_OfflineAdminCategoryMasterController());
    catCtrl.isLoading.value = false;
    catCtrl.totalCount.value = 12;
    catCtrl.rootCount.value = 4;
    catCtrl.subCount.value = 8;
    catCtrl.activeCount.value = 10;
    catCtrl.inactiveCount.value = 2;
    catCtrl.treeCategories.assignAll([
      CategoryTreeModel(
        id: 1,
        name: 'Pulses & Grains',
        level: 1,
        status: 'active',
        children: [],
        brands: [],
      ),
    ]);

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(home: AdminCategoryMasterScreen()));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Category Master'), findsOneWidget);
    expect(find.text('Manage agricultural commodity categories & hierarchy'), findsOneWidget);

    // Verify summary stats
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Pulses & Grains'), findsOneWidget);

    // Verify Add Category FAB
    expect(find.text('Add Category'), findsOneWidget);
  });

  testWidgets('AdminRecordDetailScreen renders HeroHeader and detail cards', (tester) async {
    final config = AdminModuleConfig(
      key: 'test_commodity',
      title: 'Commodity',
      icon: Icons.grain,
      listEndpoint: '/api/commodities/',
      titleKeys: ['name'],
      subtitleKeys: ['code'],
    );

    final record = AdminRecord({
      'id': 1,
      'name': 'Yellow Peas',
      'code': 'YP-100',
    });

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(
      home: AdminRecordDetailScreen(
        config: config,
        record: record,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Commodity Details'), findsOneWidget);
    expect(find.text('Inspect catalog record fields & metadata'), findsOneWidget);
    expect(find.text('Yellow Peas'), findsOneWidget);
  });

  testWidgets('AdminRecordFormScreen renders HeroHeader and modernized save button', (tester) async {
    final config = AdminModuleConfig(
      key: 'test_commodity',
      title: 'Commodity',
      icon: Icons.grain,
      listEndpoint: '/api/commodities/',
      titleKeys: ['name'],
      subtitleKeys: ['code'],
      fields: [
        const AdminFieldConfig('name', 'Commodity Name', required: true),
      ],
    );

    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(
      home: AdminRecordFormScreen(config: config),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Create Commodity'), findsOneWidget);
    expect(find.text('Configure catalog and system parameters'), findsOneWidget);

    // Verify form card and CTA
    expect(find.text('Commodity Name *'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });
}
