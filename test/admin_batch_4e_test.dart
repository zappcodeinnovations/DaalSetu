import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_catalog/view/admin_roles_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_permissions_matrix_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_sub_admin_permissions_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_complaints_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({
      'user_role': 'admin',
    });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AdminRolesScreen renders HeroHeader with drawer leading and Add Role button', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: AdminRolesScreen(showAdminDrawer: true),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Roles'), findsOneWidget);
    expect(find.text('Manage administrative roles & permissions'), findsOneWidget);

    // Verify Add Role FAB
    expect(find.text('Add Role'), findsOneWidget);
  });

  testWidgets('AdminPermissionsMatrixScreen renders HeroHeader and permission controls', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: AdminPermissionsMatrixScreen(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Permissions Matrix'), findsOneWidget);
    expect(find.text('Global role-based access control rules'), findsOneWidget);
  });

  testWidgets('AdminSubAdminPermissionsScreen renders HeroHeader and Sub Admin details', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: AdminSubAdminPermissionsScreen(
        subAdminId: '42',
        subAdminName: 'Vikram Singh',
      ),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Sub Admin Permissions'), findsOneWidget);
  });

  testWidgets('AdminComplaintsView renders HeroHeader, KPI metrics, and dispute tickets', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: AdminComplaintsView(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Complaints & Issues'), findsOneWidget);
    expect(find.text('Platform trade dispute management & audit logs'), findsOneWidget);

    // Verify KPI indicators and ticket card
    expect(find.text('Open Issues'), findsOneWidget);
    expect(find.text('Resolved MTD'), findsOneWidget);
    expect(find.text('CMP-1042'), findsOneWidget);
  });
}
