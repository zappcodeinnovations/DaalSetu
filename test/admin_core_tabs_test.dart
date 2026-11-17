import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/kyc_users/view/kyc_user_view.dart';
import 'package:daalsetu/modules/kyc_users/controller/kyc_user_controller.dart';
import 'package:daalsetu/modules/products/view/product_view.dart';
import 'package:daalsetu/modules/products/controller/product_controller.dart';
import 'package:daalsetu/modules/contracts/view/contract_view.dart';
import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineProductController extends ProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

class _OfflineContractController extends ContractController {
  @override
  Future<void> fetchContracts({bool silent = false}) async {}
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

  testWidgets('KycUsersScreen renders HeroHeader, KPI summary pods and search bar', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = Get.put(KycController());
    controller.isLoading.value = false;
    controller.kycUsers.clear();

    await tester.pumpWidget(GetMaterialApp(
      home: KycUsersScreen(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('KYC Users'), findsOneWidget);
    expect(find.text('Manage KYC verification and approvals'), findsOneWidget);

    // Verify summary KPI titles
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Approved'), findsWidgets);
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('Total Users'), findsOneWidget);
  });

  testWidgets('ProductScreen renders HeroHeader, Create Offer gradient CTA and empty state', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = Get.put<ProductController>(_OfflineProductController());
    controller.isLoading.value = false;
    controller.products.clear();

    await tester.pumpWidget(GetMaterialApp(
      home: ProductScreen(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Live trading offers & catalog management'), findsOneWidget);

    // Verify Create Offer CTA
    expect(find.text('Create Offer'), findsOneWidget);
    expect(find.text('No offers available'), findsOneWidget);
  });

  testWidgets('ContractsScreen renders HeroHeader and filter tabs', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = Get.put<ContractController>(_OfflineContractController());
    controller.isLoading.value = false;
    controller.contracts.clear();

    await tester.pumpWidget(const GetMaterialApp(
      home: ContractsScreen(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Contracts'), findsOneWidget);

    // Verify filter options
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('In Transit'), findsOneWidget);
  });
}
