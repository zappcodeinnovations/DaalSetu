import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/model/contract_model.dart';
import 'package:daalsetu/modules/contracts/view/contract_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockContractController extends ContractController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  Future<void> fetchContracts() async {}

  @override
  Future<void> fetchContractDetail(int contractId) async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Contract Model ID Parsing', () {
    test('ContractModel parses product_id and interest_id correctly', () {
      final model = ContractModel.fromJson({
        'id': 84,
        'contract_id': 'JBC2610173027',
        'product_title': '50',
        'product_category_name': 'Polished',
        'product_id': 152,
        'interest_id': 143,
        'buyer_name': 'Test Buyer',
        'seller_name': 'Test Seller',
        'display_buyer_id': 'BUY123',
        'display_seller_id': 'SEL123',
        'deal_amount': '500.00',
        'deal_quantity': '3.900',
        'amount_unit': 'kg',
        'quantity_unit': 'qtl',
        'loading_from': 'Shop no 12',
        'loading_to': 'Amalner',
        'status': 'active',
        'created_at': '2026-10-17 04:47:00',
      });

      expect(model.productId, 152);
      expect(model.interestId, 143);
      expect(model.productTitle, '50');

      final detail = ContractDetailModel.fromContractModel(model);
      expect(detail.productId, 152);
      expect(detail.interestId, 143);
      expect(detail.productTitle, '50');
    });

    test('ContractDetailModel.fromJson parses product_id and other IDs', () {
      final detail = ContractDetailModel.fromJson({
        'id': 84,
        'contract_id': 'JBC2610173027',
        'product_id': 152,
        'product_title': '50',
        'product_category_name': 'Polished',
        'buyer_id': 137,
        'seller_id': 136,
        'deal_amount': '500.00',
        'deal_quantity': '3.900',
        'amount_unit': 'kg',
        'quantity_unit': 'qtl',
        'loading_from': 'Shop no 12',
        'loading_to': 'Amalner',
        'status': 'active',
        'created_at': '2026-10-17 04:47:00',
      });

      expect(detail.productId, 152);
      expect(detail.buyerId, 137);
      expect(detail.sellerId, 136);
      expect(detail.productTitle, '50');
    });
  });

  group('ContractDetailScreen UI', () {
    testWidgets('displays Offer label and "50 (ID: 152)" in ContractDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockContractController();
      Get.put<ContractController>(controller);

      final detail = ContractDetailModel.fromJson({
        'id': 84,
        'contract_id': 'JBC2610173027',
        'product_id': 152,
        'product_title': '50',
        'product_category_name': 'Polished',
        'buyer_id': 137,
        'seller_id': 136,
        'deal_amount': '500.00',
        'deal_quantity': '3.900',
        'amount_unit': 'kg',
        'quantity_unit': 'qtl',
        'loading_from': 'Shop no 12',
        'loading_to': 'Amalner',
        'status': 'active',
        'created_at': '2026-10-17 04:47:00',
      });
      controller.contractDetail.value = detail;

      await tester.pumpWidget(
        GetMaterialApp(
          home: const Scaffold(body: SizedBox()),
          getPages: [
            GetPage(
              name: '/contract',
              page: () => const ContractDetailScreen(),
            ),
          ],
        ),
      );
      Get.toNamed('/contract', arguments: 84);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Offer'), findsOneWidget);
      expect(find.text('50 (ID: 152)'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Polished'), findsOneWidget);
    });
  });
}
