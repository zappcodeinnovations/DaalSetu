import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/model/seller_product_model.dart';
import 'package:daalsetu/modules/seller/products/view/seller_product_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockSellerProductController extends SellerProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Seller Product Status Parsing & Deactivation', () {
    test('SellerProductModel parses is_active with various data types', () {
      final p1 = SellerProductModel.fromJson({
        'id': 101,
        'title': 'URADDAL',
        'is_active': false,
        'status': 'available',
      });
      expect(p1.isActive, isFalse);

      final p2 = SellerProductModel.fromJson({
        'id': 102,
        'title': 'URADDAL',
        'is_active': 0,
        'status': 'available',
      });
      expect(p2.isActive, isFalse);

      final p3 = SellerProductModel.fromJson({
        'id': 103,
        'title': 'URADDAL',
        'is_active': 'false',
        'status': 'available',
      });
      expect(p3.isActive, isFalse);

      final p4 = SellerProductModel.fromJson({
        'id': 104,
        'title': 'URADDAL',
        'is_active': true,
        'status': 'available',
      });
      expect(p4.isActive, isTrue);
    });
  });

  group('SellerProductCard Layout Verification', () {
    testWidgets('Card renders Title, Category, Price with ample width and does not squish vertically',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockSellerProductController();
      Get.put<SellerProductController>(controller);

      final product = SellerProductModel.fromJson({
        'id': 178,
        'title': 'URADDAL',
        'category_name': 'Urad Dal',
        'brand_name': 'Fortune',
        'amount': '50.00',
        'amount_unit': 'qtl',
        'status': 'sold_pending_confirmation',
        'is_active': true,
        'bag_count': 10,
        'packing_weight_kg': '50',
        'loading_location': 'nagpur, Maharashtra',
      });

      controller.products.assignAll([product]);
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: SellerProductView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify all elements are visible
      expect(find.text('URADDAL'), findsOneWidget);
      expect(find.text('Urad Dal | Fortune'), findsOneWidget);
      expect(find.text('₹50.00 / qtl'), findsOneWidget);
      expect(find.text('PENDING CONFIRMATION'), findsOneWidget);

      // 2. Verify Title text width is substantial and not squished into a narrow 1-char column
      final titleFinder = find.text('URADDAL');
      final titleSize = tester.getSize(titleFinder);
      expect(titleSize.width, greaterThan(60.0),
          reason: 'Title must have horizontal width and not be squished vertically into 1 char width');
      expect(titleSize.height, lessThan(40.0),
          reason: 'Title should not wrap every character vertically');

      // 3. Verify Category text width is not squished
      final categoryFinder = find.text('Urad Dal | Fortune');
      final categorySize = tester.getSize(categoryFinder);
      expect(categorySize.width, greaterThan(80.0));
    });

    testWidgets('Deactivated product card displays INACTIVE badge even if status is available',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockSellerProductController();
      Get.put<SellerProductController>(controller);

      final product = SellerProductModel.fromJson({
        'id': 178,
        'title': 'URADDAL',
        'category_name': 'Urad Dal',
        'brand_name': 'Fortune',
        'amount': '50.00',
        'amount_unit': 'qtl',
        'status': 'available',
        'is_active': false, // Deactivated by seller!
      });

      controller.products.assignAll([product]);
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: SellerProductView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show INACTIVE badge
      expect(find.text('INACTIVE'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsNothing);
    });

    testWidgets('Long location string does not cause right overflow on a narrow mobile screen',
        (tester) async {
      // Set to narrow screen (360 x 800) matching standard mobile viewport
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockSellerProductController();
      Get.put<SellerProductController>(controller);

      final product = SellerProductModel.fromJson({
        'id': 179,
        'title': 'mix daal',
        'category_name': 'Toor Dal',
        'brand_name': 'Organic Tattva',
        'amount': '45.00',
        'amount_unit': 'qtl',
        'status': 'available',
        'is_active': false,
        'bag_count': 0,
        'packing_weight_kg': '50',
        'loading_location': 'nagpur, Nagpur, Maharashtra, India -> test address, Nagpur',
      });

      controller.products.assignAll([product]);
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: SellerProductView(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No overflow exception should occur
      expect(tester.takeException(), isNull);
      expect(find.text('mix daal'), findsOneWidget);
      expect(find.text('nagpur, Nagpur, Maharashtra, India -> test address, Nagpur'), findsOneWidget);
      expect(find.text('0 Bags'), findsOneWidget);
      expect(find.text('50.0kg'), findsOneWidget);
    });
  });

  group('Buyer Offer Filtering', () {
    test('SellerProductModel identifies buyer offers created from buyer requests', () {
      final buyerOfferItem = SellerProductModel.fromJson({
        'id': 180,
        'title': 'mix daal',
        'description': 'Created from buyer request final confirmation.',
        'amount': '45.00',
        'is_active': false,
      });
      expect(buyerOfferItem.isBuyerOffer, isTrue);

      final explicitBuyerOffer = SellerProductModel.fromJson({
        'id': 181,
        'title': 'urad daal',
        'is_buyer_offer': true,
        'amount': '50.00',
      });
      expect(explicitBuyerOffer.isBuyerOffer, isTrue);

      final normalSellerProduct = SellerProductModel.fromJson({
        'id': 182,
        'title': 'Normal Seller Offer',
        'description': 'Premium Sortex Dal',
        'amount': '60.00',
        'is_active': true,
      });
      expect(normalSellerProduct.isBuyerOffer, isFalse);
    });
  });
}

