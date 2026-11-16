import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'seller'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Seller Drawer renders modern hero header and all 5 role-based sections',
      (tester) async {
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          drawer: const AdminDrawer(activeKey: 'dashboard'),
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 1. Verify Header
    expect(find.text('SELLER PANEL'), findsOneWidget);
    expect(find.byTooltip('Close menu'), findsOneWidget);

    // 2. Verify Section Headers
    expect(find.text('OVERVIEW & BUSINESS'), findsOneWidget);
    expect(find.text('OFFERS & INVENTORY'), findsOneWidget);
    expect(find.text('DEALS & DISPATCH'), findsOneWidget);
    expect(find.text('INSIGHTS & FILES'), findsOneWidget);
    expect(find.text('PREFERENCES & ACCOUNT'), findsOneWidget);

    // 3. Verify Menu Items
    final sellerItems = [
      'Dashboard',
      'Category Master',
      'Companies',
      'My Branches',
      'Create Offer',
      'My Products',
      'Buyer Requirements',
      'Buyer Offers',
      'Brand & Tag Master',
      'Contracts',
      'Consignments',
      'Delivery Challans',
      'My Analytics',
      'Downloads',
      'Settings',
      'Log Out',
    ];

    for (final item in sellerItems) {
      expect(find.text(item), findsOneWidget,
          reason: 'Seller Drawer must display $item');
    }
  });
}
