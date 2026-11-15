import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'buyer'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Buyer Drawer renders modern hero header and all role-based sections',
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
    expect(find.text('BUYER PANEL'), findsOneWidget);
    expect(find.byTooltip('Close menu'), findsOneWidget);

    // 2. Verify Section Headers
    expect(find.text('OVERVIEW & BUSINESS'), findsOneWidget);
    expect(find.text('MARKETPLACE & OFFERS'), findsOneWidget);
    expect(find.text('DEALS & LOGISTICS'), findsOneWidget);
    expect(find.text('INSIGHTS & FILES'), findsOneWidget);
    expect(find.text('PREFERENCES & ACCOUNT'), findsOneWidget);

    // 3. Verify Menu Items
    final buyerItems = [
      'Dashboard',
      'My Categories',
      'Registered Company',
      'Browse Offers',
      "Today's Offers",
      'My Interests',
      'Buyer Requirements',
      'Deals',
      'Delivery Challans',
      'Consignments',
      'Branches',
      'My Analytics',
      'Downloads',
      'Settings',
      'Log Out',
    ];

    for (final item in buyerItems) {
      expect(find.text(item), findsOneWidget, reason: 'Expected $item in Buyer Drawer');
    }

    // 4. Close drawer via close button
    await tester.tap(find.byTooltip('Close menu'));
    await tester.pumpAndSettle();

    // Drawer is closed
    expect(find.text('BUYER PANEL'), findsNothing);
  });
}
