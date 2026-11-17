import 'package:daalsetu/modules/nav_bar/view/nav_page.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/view/seller_product_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _EmptyProducts extends SellerProductController {
  _EmptyProducts() {
    isLoading.value = false;
  }

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

void main() {
  tearDown(() => Get.reset());

  for (final bottomInset in [0.0, 24.0]) {
    testWidgets(
      'Add Product sits above floating navigation with $bottomInset system inset',
      (tester) async {
        Get.testMode = true;
        Get.put<SellerProductController>(_EmptyProducts());
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(bottom: bottomInset);
        tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              extendBody: true,
              body: const SellerProductView(),
              bottomNavigationBar: GlassNavBar(
                currentIndex: 1,
                role: 'seller',
                onTap: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.byKey(const Key('seller-add-product-button'));
        final navigation = find.byKey(
          const Key('floating_glass_nav_bar_container'),
        );
        expect(
          tester.getRect(button).bottom,
          lessThan(tester.getRect(navigation).top),
        );
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
