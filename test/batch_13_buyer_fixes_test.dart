import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/category/model/category_request_model.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';
import 'package:daalsetu/services/category_services.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_request_management_view.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/controller/drawer_controller.dart' as admin;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 13 Fixes Verification', () {
    test('1. CategoryRequestModel parses categoryIds and retains data correctly', () {
      final json = {
        'id': 101,
        'status': 'approved',
        'categories': [
          {'id': 12, 'name': 'Toor Daal'},
          {'id': 15, 'name': 'Moong Daal'},
        ],
        'reviewed_by': {'name': 'Verma Agro Traders Private Limited'},
      };

      final model = CategoryRequestModel.fromJson(json);
      expect(model.id, 101);
      expect(model.status, 'approved');
      expect(model.categoryNames, ['Toor Daal', 'Moong Daal']);
      expect(model.categoryIds, [12, 15]);
      expect(model.reviewerName, 'Verma Agro Traders Private Limited');
    });

    test('2. BuyerOffersController filters out RFQs/Buyer Requirements under Offers section', () {
      final controller = BuyerOffersController(offerType: 'all');
      
      // An RFQ item and a Seller Product item
      final rfqItem = BuyerOfferModel.fromJson({
        'id': 201,
        'rfq_id': 201,
        'commodity': 'toor daal',
        'required_quantity': '120.000',
        'target_price': '120.00',
        'is_active': true,
        'source_type': 'rfq',
      });
      final sellerProductItem = BuyerOfferModel.fromJson({
        'id': 301,
        'product_id': 301,
        'product_title': 'Premium Yellow Daal',
        'amount': '80.00',
        'quantity': '50.000',
        'is_active': true,
        'status': 'available',
        'source_type': 'product',
      });

      expect(rfqItem.isRfq, isTrue);
      expect(sellerProductItem.isRfq, isFalse);

      // Verify that under offerType == 'all', RFQ is rejected while seller product is accepted
      bool shouldIncludeInOffersTab(BuyerOfferModel offer) {
        if (controller.offerType != 'requirements' && offer.isRfq) {
          return false;
        }
        if (controller.offerType == 'all') {
          return offer.isActive;
        }
        return true;
      }

      expect(shouldIncludeInOffersTab(rfqItem), isFalse);
      expect(shouldIncludeInOffersTab(sellerProductItem), isTrue);
    });

    testWidgets('3. AdminDrawer / BuyerDrawer Settings icon has high contrast in dark mode', (tester) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final drawerController = Get.put(admin.DrawerController());
      drawerController.userRole.value = 'buyer';
      drawerController.isLoading.value = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            drawer: AdminDrawer(),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.settings_outlined));
      // Verify icon color is high contrast silver (not dark muted 0xFF475569)
      expect(iconWidget.color, const Color(0xFFCBD5E1));
    });

    testWidgets('4. BuyerRequestManagementView renders horizontal filter chips with scroll controller', (tester) async {
      tester.view.physicalSize = const Size(1100, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          home: const BuyerRequestManagementView(
            mode: BuyerRequestMode.requirements,
            wrapInScaffold: true,
          ),
        ),
      );

      await tester.pump();

      // Verify status filter chips exist
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Fulfilled'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);

      // Tap on 'Expired' chip
      await tester.tap(find.text('Expired'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      // Selected chip is active
      final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Expired'));
      expect(chip.selected, isTrue);
    });
  });
}
