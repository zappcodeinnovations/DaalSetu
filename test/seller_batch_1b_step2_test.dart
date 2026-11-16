import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/seller/products/view/edit_offer_view.dart';
import 'package:daalsetu/modules/seller/products/view/seller_media_gallery_view.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_media_controller.dart';
import 'package:daalsetu/modules/seller/products/view/seller_offer_interests_view.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_negotiation_controller.dart';
import 'package:daalsetu/widgets/hero_header.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('EditOfferView renders HeroHeader cleanly', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: EditOfferView(productId: 1),
      ),
    );
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Edit Offer"), findsOneWidget);
    expect(find.text("Commodity pricing, delivery window & terms"), findsOneWidget);
  });

  testWidgets('SellerMediaGalleryView renders HeroHeader with tabs and upload FAB', (tester) async {
    final controller = Get.put(SellerMediaController(productId: 1), tag: 'seller_media_1');
    controller.isLoading.value = false;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SellerMediaGalleryView(productId: 1),
      ),
    );
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Media Gallery"), findsOneWidget);
    expect(find.text("Images"), findsOneWidget);
    expect(find.text("Videos"), findsOneWidget);
  });

  testWidgets('SellerOfferInterestsView renders HeroHeader and empty state', (tester) async {
    final controller = Get.put(SellerNegotiationController(productId: 0), tag: 'seller_negotiation_0');
    controller.isLoading.value = false;
    controller.interestsList.clear();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SellerOfferInterestsView(),
      ),
    );
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text("Buyer Interests"), findsOneWidget);
    expect(find.text("No buyer interests yet for this offer"), findsOneWidget);

    controller.onClose();
  });
}
