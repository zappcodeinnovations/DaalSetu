import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/view/contract_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockContractController extends ContractController {
  @override
  void onInit() {
    userRole.value = 'admin';
    super.onInit();
  }

  @override
  Future<void> fetchContracts({bool silent = false}) async {}

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

  group('Delivery Challan Model Parsing', () {
    test('ContractDetailModel parses delivery challan fields correctly', () {
      final modelWithChallan = ContractDetailModel.fromJson({
        'id': 170,
        'contract_id': 'JBC2611055755',
        'product_id': 178,
        'product_title': 'toor daal',
        'status': 'active',
        'has_delivery_challan': true,
        'delivery_challan_id': 42,
        'delivery_challan_number': 'DC-2026-0042',
      });

      expect(modelWithChallan.hasDeliveryChallan, isTrue);
      expect(modelWithChallan.deliveryChallanId, equals(42));
      expect(modelWithChallan.deliveryChallanNumber, equals('DC-2026-0042'));

      final modelWithoutChallan = ContractDetailModel.fromJson({
        'id': 171,
        'contract_id': 'JBC2611055756',
        'product_id': 178,
        'product_title': 'toor daal',
        'status': 'active',
      });

      expect(modelWithoutChallan.hasDeliveryChallan, isFalse);
      expect(modelWithoutChallan.deliveryChallanId, isNull);
      expect(modelWithoutChallan.deliveryChallanNumber, isNull);
    });
  });

  group('ContractDetailScreen - Create Delivery Challan Button Visibility', () {
    testWidgets('shows "Create Delivery Challan" button when no challan has been created for active contract',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockContractController();
      Get.put<ContractController>(controller);

      final detail = ContractDetailModel.fromJson({
        'id': 170,
        'contract_id': 'JBC2611055755',
        'product_id': 178,
        'product_title': 'toor daal',
        'deal_amount': '45.00',
        'deal_quantity': '2.000',
        'amount_unit': 'qtl',
        'quantity_unit': 'qtl',
        'status': 'active',
      });
      controller.contractDetail.value = detail;
      controller.hasDeliveryChallan.value = false;
      controller.isCheckingChallan.value = false;

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
      Get.toNamed('/contract', arguments: 170);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Delivery Challan'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Edit contract'), findsOneWidget);
    });

    testWidgets('HIDES "Create Delivery Challan" button when delivery challan has already been created for contract',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockContractController();
      Get.put<ContractController>(controller);

      final detail = ContractDetailModel.fromJson({
        'id': 170,
        'contract_id': 'JBC2611055755',
        'product_id': 178,
        'product_title': 'toor daal',
        'deal_amount': '45.00',
        'deal_quantity': '2.000',
        'amount_unit': 'qtl',
        'quantity_unit': 'qtl',
        'status': 'active',
        'has_delivery_challan': true,
        'delivery_challan_id': 42,
      });
      controller.contractDetail.value = detail;
      controller.hasDeliveryChallan.value = true; // Challan already created!
      controller.isCheckingChallan.value = false;

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
      Get.toNamed('/contract', arguments: 170);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Button must NOT be shown
      expect(find.text('Create Delivery Challan'), findsNothing);
      // Other buttons remain visible
      expect(find.text('Download PDF'), findsOneWidget);
      expect(find.text('Edit contract'), findsOneWidget);
    });

    testWidgets('HIDES "Create Delivery Challan" button when contract is not active',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockContractController();
      Get.put<ContractController>(controller);

      final detail = ContractDetailModel.fromJson({
        'id': 170,
        'contract_id': 'JBC2611055755',
        'product_id': 178,
        'product_title': 'toor daal',
        'deal_amount': '45.00',
        'deal_quantity': '2.000',
        'amount_unit': 'qtl',
        'quantity_unit': 'qtl',
        'status': 'received', // Not active
      });
      controller.contractDetail.value = detail;
      controller.hasDeliveryChallan.value = false;
      controller.isCheckingChallan.value = false;

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
      Get.toNamed('/contract', arguments: 170);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Button must NOT be shown for non-active contracts
      expect(find.text('Create Delivery Challan'), findsNothing);
    });
  });
}

