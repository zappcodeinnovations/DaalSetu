import 'package:daalsetu/modules/nav_bar/controller/nav_controller.dart';
import 'package:daalsetu/modules/seller/challans/controller/seller_challan_controller.dart';
import 'package:daalsetu/modules/seller/challans/model/seller_challan_model.dart';
import 'package:daalsetu/modules/seller/challans/view/seller_delivery_challan_view.dart';
import 'package:daalsetu/modules/seller/consignments/view/seller_consignments_view.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:daalsetu/modules/seller/products/view/seller_product_view.dart';
import 'package:daalsetu/widgets/back_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeProducts extends SellerProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

class _FakeChallans extends SellerChallanController {
  @override
  void onInit() {
    challansList.assignAll([SellerChallanModel(id: 3, challanNumber: 'DC-1', status: 'draft')]);
  }

  @override
  Future<void> fetchChallans() async {}
}

class _FakeConsignments extends SellerConsignmentController {
  @override
  void onInit() {
    rows.assignAll([
      {'id': 1, 'contract_id': 'JBC1', 'status': 'active', 'is_dispatched': false, 'can_mark_ready': true},
      {'id': 2, 'contract_id': 'JBC2', 'status': 'active', 'is_dispatched': false, 'can_mark_ready': true},
    ]);
  }

  @override
  Future<void> fetch({bool silent = false}) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('My Products: the back arrow of a bottom-bar tab goes to the dashboard tab', (tester) async {
    final nav = Get.put(BottomNavController());
    nav.selectedIndex.value = 1; // My Products tab
    final products = _FakeProducts();
    Get.put<SellerProductController>(products);
    products.isLoading.value = false;
    await tester.pumpWidget(const GetMaterialApp(home: SellerProductView()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(nav.selectedIndex.value, 0);
  });

  testWidgets('a pushed screen still just goes back', (tester) async {
    final nav = Get.put(BottomNavController());
    nav.selectedIndex.value = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (inner) => Scaffold(
                  body: TextButton(onPressed: () => goBackOrHome(inner), child: const Text('back')),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(nav.selectedIndex.value, 1); // untouched
  });

  testWidgets('My Products: "Interests (n)" stays on one line next to Stock and Media', (tester) async {
    phone(tester);
    final products = _FakeProducts();
    Get.put<SellerProductController>(products);
    products.products.assignAll([
      SellerProductModel.fromJson({
        'id': 1,
        'title': 'YELLOW DAAL',
        'category_name': 'Split Yellow',
        'amount': '80.00',
        'amount_unit': 'qtl',
        'status': 'available',
        'is_active': true,
        'interest_count': 12,
      }),
    ]);
    products.isLoading.value = false;
    await tester.pumpWidget(const GetMaterialApp(home: SellerProductView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final label = find.text('Interests (12)');
    expect(label, findsOneWidget);
    expect(tester.getSize(label).height, lessThan(24), reason: 'one line, not "Interests" over "(12)"');
    // the three buttons sit side by side in one row
    final interests = tester.getRect(find.widgetWithText(OutlinedButton, 'Stock')).top;
    expect(tester.getRect(find.widgetWithText(OutlinedButton, 'Media')).top, interests);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DISPATCH SHIPMENT: the label sits fully inside its button', (tester) async {
    phone(tester);
    Get.put<SellerChallanController>(_FakeChallans());
    await tester.pumpWidget(const GetMaterialApp(home: SellerDeliveryChallanView()));
    await tester.pump();
    final button = tester.getRect(find.widgetWithText(ElevatedButton, 'DISPATCH SHIPMENT'));
    final text = tester.getRect(find.text('DISPATCH SHIPMENT'));
    expect(text.top, greaterThanOrEqualTo(button.top));
    expect(text.bottom, lessThanOrEqualTo(button.bottom));
    expect(button.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('MARK READY FOR LOADING: the label sits fully inside its button on every card', (tester) async {
    phone(tester);
    Get.put<SellerConsignmentController>(_FakeConsignments());
    await tester.pumpWidget(const GetMaterialApp(home: SellerConsignmentsView()));
    await tester.pump();
    final buttons = find.widgetWithText(ElevatedButton, 'MARK READY FOR LOADING');
    expect(buttons, findsWidgets);
    for (var i = 0; i < tester.widgetList(buttons).length; i++) {
      final button = tester.getRect(buttons.at(i));
      final text = tester.getRect(find.descendant(of: buttons.at(i), matching: find.text('MARK READY FOR LOADING')));
      expect(text.top, greaterThanOrEqualTo(button.top));
      expect(text.bottom, lessThanOrEqualTo(button.bottom));
      expect(button.height, greaterThanOrEqualTo(44));
    }
    expect(tester.takeException(), isNull);
  });
}
