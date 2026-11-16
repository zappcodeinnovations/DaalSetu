import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/offers/view/transporter_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/modules/transporter/rfq/view/transporter_rfq_view.dart';
import 'package:daalsetu/modules/seller/rfq/controller/seller_rfq_controller.dart';
import 'package:daalsetu/modules/seller/rfq/model/seller_rfq_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineBuyerOffersController extends BuyerOffersController {
  _OfflineBuyerOffersController({required super.offerType});

  @override
  Future<void> fetchOffers({bool silent = false}) async {}
}

class _OfflineSellerRfqController extends SellerRfqController {
  @override
  Future<void> fetchRFQs() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('TransporterOffersView renders HeroHeader with 4 tabs and Offer cards', (tester) async {
    for (final type in ['all', 'today', 'pending', 'previous']) {
      final ctrl = Get.put<BuyerOffersController>(
        _OfflineBuyerOffersController(offerType: type),
        tag: type,
      );
      ctrl.isLoading.value = false;
      ctrl.offersList.assignAll([
        BuyerOfferModel(
          id: 1,
          title: "Premium Desi Chana Offer",
          requestedAmount: "5600",
          requestedQuantity: "100",
          quantityUnit: "Qtl",
          status: "ACTIVE",
          displayTitle: "Premium Desi Chana Offer",
          displayPrice: "₹5600",
          displayQuantity: "100 Qtl",
          displayStatus: "ACTIVE",
        ),
      ]);
    }

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterOffersView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Pulse Offers'), findsOneWidget);
    expect(find.text('Active commodity trade offers'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);

    // Verify Offer Card
    expect(find.text('Premium Desi Chana Offer'), findsOneWidget);
    expect(find.text('₹5600'), findsOneWidget);
    expect(find.text('100 Qtl'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('TransporterRfqView renders HeroHeader and Buyer RFQ tender cards', (tester) async {
    final rfqCtrl = Get.put<SellerRfqController>(_OfflineSellerRfqController());
    rfqCtrl.isLoading.value = false;
    rfqCtrl.rfqList.assignAll([
      SellerRfqModel(
        id: 201,
        rfqId: "RFQ-2026-901",
        title: "Toor Daal Procurement",
        categoryName: "Toor Daal Grade A",
        buyerName: "Rajesh Agro Traders",
        requiredQuantity: "250",
        quantityUnit: "Qtl",
        targetPrice: "6800.00",
        priceUnit: "Qtl",
        status: "ACTIVE",
        targetBranches: [],
        quotationCount: 2,
        canQuote: true,
        quotations: [],
      ),
    ]);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterRfqView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Buyer Requirements'), findsOneWidget);
    expect(find.text('Active buyer procurement tenders & RFQ'), findsOneWidget);

    // Verify RFQ Card
    expect(find.text('RFQ'), findsOneWidget);
    expect(find.text('Toor Daal Grade A'), findsOneWidget);
    expect(find.text('₹6800.00/Qtl'), findsOneWidget);
    expect(find.text('Req: 250 Qtl'), findsOneWidget);
    expect(find.text('Buyer: Rajesh Agro Traders'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });
}
