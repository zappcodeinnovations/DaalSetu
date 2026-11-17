import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_catalog/view/admin_module_list_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/negotiation_page.dart';
import 'package:daalsetu/modules/admin_catalog/view/assign_driver_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/assign_vehicle_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/approve_deal_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/stock_history_dialog.dart';
import 'package:daalsetu/modules/products/model/offer_interest_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test_token',
      'user_role': 'admin',
    });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AdminModuleListScreen renders HeroHeader, search bar, and Create FAB', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: AdminModuleListScreen(
        moduleKey: 'sub_categories',
        showAdminDrawer: false,
      ),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Sub-Category Master'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('NegotiationPage renders HeroHeader, Negotiation Summary, and Negotiation Log', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final dummyInterest = OfferInterestModel(
      id: 101,
      buyerName: 'Ramesh Agro',
      offerPrice: '4500.00',
      requiredQuantity: '100.00',
      status: 'interested',
    );

    await tester.pumpWidget(GetMaterialApp(
      home: NegotiationPage(
        offerId: '55',
        offerTitle: 'Yellow Peas Grade A',
        interest: dummyInterest,
      ),
    ));
    await tester.pump();

    // Verify HeroHeader and cards
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Negotiation: Yellow Peas Grade A'), findsOneWidget);
    expect(find.text('Negotiation Summary'), findsOneWidget);
    expect(find.text('Negotiation Log'), findsOneWidget);
  });

  testWidgets('AssignDriverDialog renders curved saffron header with vehicle number', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(
        body: AssignDriverDialog(
          vehicleId: '12',
          vehicleNumber: 'MH 12 AB 1234',
          assignedDriverName: 'Sunil Kumar',
        ),
      ),
    ));
    await tester.pump();

    // Verify header and error or content state
    expect(find.text('Assign Driver'), findsOneWidget);
    expect(find.text('MH 12 AB 1234'), findsOneWidget);
    expect(find.text('Could not load drivers'), findsOneWidget);
  });

  testWidgets('AssignVehicleDialog renders curved saffron header with driver name', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(
        body: AssignVehicleDialog(
          driverId: '99',
          driverName: 'Rajesh Driver',
        ),
      ),
    ));
    await tester.pump();

    // Verify header
    expect(find.text('Assign Vehicle'), findsOneWidget);
    expect(find.text('Driver: Rajesh Driver'), findsOneWidget);
  });

  testWidgets('ApproveDealDialog renders dialog with Accept Interest button', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(
        body: ApproveDealDialog(
          buyerName: 'Kisan Traders',
          offerTitle: 'Desi Chana 50KG',
        ),
      ),
    ));
    await tester.pump();

    // Verify dialog elements
    expect(find.text('Approve Deal'), findsOneWidget);
    expect(find.text('Accept Interest'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('StockHistoryDialog renders dialog with Stock History title', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(
        body: StockHistoryDialog(
          productId: '10',
          productTitle: 'Moong Whole Special',
          sellerName: 'Agro Farms',
          currentStock: '250 QTL',
        ),
      ),
    ));
    await tester.pump();

    // Verify dialog elements
    expect(find.text('Stock History'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}
