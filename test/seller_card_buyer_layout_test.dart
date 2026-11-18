import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:daalsetu/modules/seller/products/view/seller_product_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Controller extends SellerProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

/// The seller's My Products card uses the buyer's Offers card layout.
void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester tester, Map<String, dynamic> json, {Size size = const Size(360, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _Controller();
    Get.put<SellerProductController>(controller);
    controller.products.assignAll([SellerProductModel.fromJson(json)]);
    controller.isLoading.value = false;
    await tester.pumpWidget(const GetMaterialApp(home: SellerProductView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  const offer = {
    'id': 7,
    'title': 'urad daal',
    'category_name': 'Urad Dal',
    'brand_name': 'TATA sampann',
    'amount': '25.00',
    'amount_unit': 'qtl',
    'status': 'active',
    'is_active': true,
    'remaining_quantity': '16.700',
    'quantity_unit': 'qtl',
    'interested_count': 3,
    'bag_count': 167,
    'packing_weight_kg': '10',
    'loading_location': 'nagpur it park off to 143 building, Nagpur, Maharashtra',
    'created_at': '2026-11-17T10:00:00Z',
  };

  testWidgets('shows the quantity | price box, the heart count and the metadata chips', (tester) async {
    await pump(tester, offer);
    expect(find.text('Available Quantity'), findsOneWidget);
    expect(find.text('16.700 QTL'), findsOneWidget);
    expect(find.text('Offer Price'), findsOneWidget);
    expect(find.text('₹25.00 / qtl'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('167 Bags'), findsOneWidget);
    expect(find.text('10.0kg'), findsOneWidget);
    expect(find.text('17 Nov 2026'), findsOneWidget);
    // Seller actions stay.
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Interests (3)'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without stock data the quantity comes from bags x packing', (tester) async {
    await pump(tester, {...offer, 'remaining_quantity': null, 'original_quantity': null});
    expect(find.text('16.700 QTL'), findsOneWidget); // 167 bags x 10 kg
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long address and a small phone do not overflow', (tester) async {
    await pump(
      tester,
      {...offer, 'loading_location': 'A very long loading address ' * 6},
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
  });
}
