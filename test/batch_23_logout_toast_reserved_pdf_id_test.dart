import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/model/contract_model.dart';
import 'package:daalsetu/modules/contracts/services/contract_pdf.dart';
import 'package:daalsetu/modules/contracts/view/contract_view.dart';
import 'package:daalsetu/utils/app_snackbar.dart';

class _MockContractController extends ContractController {
  @override
  Future<void> fetchContracts({bool silent = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Bug 2: AppSnackbar.dismissAll clears active snackbars on logout',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppSnackbar.showInfo(
                  message: 'Delivery challan saved in Downloads.',
                  duration: const Duration(seconds: 6),
                );
              },
              child: const Text('Show Toast'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Toast'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Delivery challan saved in Downloads.'), findsOneWidget);

    AppSnackbar.dismissAll();
    await tester.pumpAndSettle();
    expect(find.text('Delivery challan saved in Downloads.'), findsNothing);
  });

  testWidgets(
      'Bug 3: ContractsScreen has Reserved filter and shows RESERVED badge when activeBidCount > 0',
      (WidgetTester tester) async {
    final controller = _MockContractController();
    controller.contracts.assignAll([
      ContractModel(
        id: 1,
        productTitle: 'toor daal',
        productCategory: 'pukhraj',
        contractId: 'JBC2611239663',
        buyerName: 'Mariegold farm',
        sellerName: 'Agrofarm',
        displayBuyerId: 'Mariegold farm',
        displaySellerId: 'Agrofarm',
        dealAmount: '45.00',
        dealQuantity: '100.200',
        amountUnit: 'qtl',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Nagpur',
        status: 'active',
        activeBidCount: 1,
        createdAt: '2026-11-23',
      ),
      ContractModel(
        id: 2,
        productTitle: 'masoor',
        productCategory: 'pulse&grain',
        contractId: 'JBC2611261015',
        buyerName: 'Mariegold farm',
        sellerName: 'Agrofarm',
        displayBuyerId: 'Mariegold farm',
        displaySellerId: 'Agrofarm',
        dealAmount: '54.00',
        dealQuantity: '50.100',
        amountUnit: 'qtl',
        quantityUnit: 'qtl',
        loadingFrom: 'Nagpur',
        loadingTo: 'Nagpur',
        status: 'active',
        activeBidCount: 0,
        createdAt: '2026-11-26',
      ),
    ]);
    Get.put<ContractController>(controller);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: ContractsScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Reserved filter chip is present
    expect(find.text('Reserved'), findsOneWidget);
    // toor daal contract shows RESERVED badge instead of ACTIVE
    expect(find.text('RESERVED'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    // Tapping Reserved filters only the bid-reserved contract
    await tester.tap(find.text('Reserved'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('toor daal'), findsOneWidget);
    expect(find.text('masoor'), findsNothing);
  });

  test(
      'Bug 4: buildContractPdf prints buyerUniqueId and sellerMappedId instead of farm display names',
      () async {
    final contract = ContractDetailModel.fromJson({
      'id': 1,
      'contract_id': 'JBC2611239663',
      'product_title': 'toor daal',
      'product_category': 'pukhraj',
      'deal_amount': '45.00',
      'amount_unit': 'qtl',
      'deal_quantity': '100.200',
      'quantity_unit': 'qtl',
      'status': 'active',
      'display_buyer_id': 'Mariegold farm',
      'buyer_unique_id': 'BUY-20261105-F9PJ',
      'buyer_name': 'rajesh kumar',
      'display_seller_id': 'Agrofarm',
      'seller_mapped_id': 'SEL7C2A76102D',
      'seller_name': 'Umesh Rathor',
    });

    final doc = buildContractPdf(
      contract,
      'JBC2611239663',
      deflate: (bytes) => bytes,
    );
    final bytes = await doc.save();
    final pdfString = String.fromCharCodes(bytes);

    expect(pdfString.contains('BUY-20261105-F9PJ'), isTrue);
    expect(pdfString.contains('SEL7C2A76102D'), isTrue);
    expect(pdfString.contains('Mariegold'), isFalse);
    expect(pdfString.contains('Agrofarm'), isFalse);
  });
}
