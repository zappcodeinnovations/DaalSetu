import 'package:daalsetu/modules/admin_catalog/controller/admin_offers_controller.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_offers_list_screen.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockAdminOffersController extends AdminOffersController {
  @override
  Future<void> fetchOffers({bool silent = false}) async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Admin offer card allows opening ProductDetailScreen by tapping anywhere on the card',
      (WidgetTester tester) async {
    final controller = MockAdminOffersController();
    Get.put<AdminOffersController>(controller);

    final offer = ProductModel.fromJson({
      'id': 501,
      'title': 'Toor Dal Premium Sortex',
      'description': 'High quality sortex toor dal',
      'amount': '120.00',
      'status': 'available',
      'stock_status': 'available',
      'is_active': true,
      'available_quantity': '100.000',
      'packing_weight_kg': '50.0',
      'loading_location': 'Latur, Maharashtra',
      'category': {'id': 1, 'name': 'Toor Dal'},
      'brand': {'id': 1, 'name': 'Royal', 'unique_id': 'ROYAL_01'},
      'seller': {'id': 10, 'username': 'seller1', 'full_name': 'Shri Ram Traders', 'login_username': 'seller1'},
    });

    controller.offers.assignAll([offer]);
    controller.isLoading.value = false;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: AdminOffersListScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify offer card is rendered
    expect(find.text('Toor Dal Premium Sortex'), findsOneWidget);

    // Tap anywhere on the card title
    await tester.tap(find.text('Toor Dal Premium Sortex'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify ProductDetailScreen is pushed
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });
}