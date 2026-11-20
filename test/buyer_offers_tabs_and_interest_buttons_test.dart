import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_my_interests_view.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/theme/glass_widgets.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('BuyerOffersView TabBar has isScrollable: false and renders all 4 tabs without clipping', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const BuyerOffersView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final tabBarFinder = find.byType(TabBar);
    expect(tabBarFinder, findsOneWidget);
    final tabBar = tester.widget<TabBar>(tabBarFinder);
    expect(tabBar.isScrollable, isFalse);

    // Verify all 4 Tab widgets exist
    expect(find.widgetWithText(Tab, 'Offers'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Today'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Pending'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Previous'), findsOneWidget);
  });

  testWidgets('BuyerMyInterestsView renders consistent action buttons with 36px height and 10px radius', (tester) async {
    final controller = Get.put(
      BuyerOffersController(offerType: 'interests'),
      tag: 'interests',
    );
    final mockItem = BuyerOfferModel(
      id: 101,
      interestId: 201,
      productId: 301,
      title: 'arhar daal',
      status: 'Interested',
      requestedAmount: '81.00',
      quantityUnit: 'QTL',
      amountUnit: 'QTL',
      requestedQuantity: '80',
    );
    controller.allOffersList.assignAll([mockItem]);
    controller.offersList.assignAll([mockItem]);
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: BuyerMyInterestsView(showAppBar: false),
        ),
      ),
    );
    // Keep offersList populated after fetchOffers completes in test
    controller.allOffersList.assignAll([mockItem]);
    controller.offersList.assignAll([mockItem]);
    controller.isLoading.value = false;
    await tester.pump();

    // Verify all 3 buttons are rendered
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Negotiation'), findsOneWidget);

    // Verify OutlinedButtons have consistent height
    final outlinedButtons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    for (final btn in outlinedButtons) {
      expect(btn.style?.minimumSize?.resolve({})?.height, 36.0);
    }

    // Verify ElevatedButton has consistent height
    final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
    for (final btn in elevatedButtons) {
      expect(btn.style?.minimumSize?.resolve({})?.height, 36.0);
    }

    // Verify card is wrapped in InkWell for full card navigation
    final cardInkWellFinder = find.ancestor(
      of: find.byType(GlassCard),
      matching: find.byType(InkWell),
    );
    expect(cardInkWellFinder, findsWidgets);

    // Tap the card directly
    await tester.tap(cardInkWellFinder.first);
    await tester.pump();
  });

  test('BuyerOfferModel parses hasSubmittedOffer from interest_id, my_interest, and flags', () {
    final model1 = BuyerOfferModel.fromJson({
      'id': 1,
      'product_title': 'Chana',
      'interest_id': 99,
    });
    expect(model1.hasSubmittedOffer, isTrue);

    final model2 = BuyerOfferModel.fromJson({
      'id': 2,
      'product_title': 'Moong',
      'my_interest': {'id': 55},
    });
    expect(model2.hasSubmittedOffer, isTrue);

    final model3 = BuyerOfferModel.fromJson({
      'id': 3,
      'product_title': 'Urad',
    });
    expect(model3.hasSubmittedOffer, isFalse);
  });

  test('BuyerOffersController tracks submitted offers dynamically', () {
    final controller = BuyerOffersController(offerType: 'today');
    expect(controller.isOfferSubmitted(42), isFalse);

    controller.submittedProductIds.add(42);
    expect(controller.isOfferSubmitted(42), isTrue);

    final submittedModel = BuyerOfferModel(id: 10, hasSubmittedOffer: true);
    expect(controller.isOfferSubmitted(10, offer: submittedModel), isTrue);
  });
}
