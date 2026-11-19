import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/kyc_users/controller/kyc_user_controller.dart';
import 'package:daalsetu/modules/kyc_users/view/kyc_user_view.dart';
import 'package:daalsetu/modules/products/controller/product_controller.dart';
import 'package:daalsetu/modules/products/view/product_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _OfflineProducts extends ProductController {
  @override
  Future<void> fetchProducts({bool silent = false}) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'admin'});
  });
  tearDown(Get.reset);

  Future<void> expectMenuOpensDrawer(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: screen));
    await tester.pump();
    expect(find.byType(AdminDrawer), findsNothing);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();
    expect(find.byType(AdminDrawer), findsOneWidget);
  }

  testWidgets('KYC screen: the menu icon opens the side menu', (tester) async {
    final controller = Get.put(KycController());
    controller.isLoading.value = false;
    await expectMenuOpensDrawer(tester, KycUsersScreen());
  });

  testWidgets('Products screen: the menu icon opens the side menu', (tester) async {
    Get.put<ProductController>(_OfflineProducts());
    await expectMenuOpensDrawer(tester, ProductScreen());
  });
}
