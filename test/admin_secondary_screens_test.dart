import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/users/view/user_view.dart';
import 'package:daalsetu/modules/users/view/user_detail_screen.dart';
import 'package:daalsetu/modules/users/view/add_user_screen.dart';
import 'package:daalsetu/modules/users/controller/user_controller.dart';
import 'package:daalsetu/modules/users/model/user_model.dart';
import 'package:daalsetu/modules/contracts/view/contract_edit_view.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/view/transport_bids_sheet.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineUserController extends UserController {
  @override
  Future<void> fetchUsers() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test_token',
      'user_role': 'admin',
    });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('UserManagementScreen renders HeroHeader, KPI summary pods and Add User FAB', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final controller = Get.put<UserController>(_OfflineUserController());
    controller.isLoading.value = false;
    controller.users.clear();

    await tester.pumpWidget(const GetMaterialApp(
      home: UserManagementScreen(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('Manage platform users, roles & KYC'), findsOneWidget);

    // Verify KPI summary labels
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Buyers'), findsOneWidget);
    expect(find.text('Sellers'), findsOneWidget);

    // Verify Add User gradient FAB
    expect(find.text('Add User'), findsOneWidget);
    expect(find.byIcon(IconlyLight.add_user), findsOneWidget);
  });

  testWidgets('UserDetailScreen renders HeroHeader, profile card and detailed sections', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testUser = UserModel(
      id: 1,
      username: 'ram_traders',
      firstName: 'Ram',
      lastName: 'Traders',
      mobile: '9876543210',
      tags: [],
      role: 'buyer',
      kycStatus: 'approved',
      accountStatus: 'active',
      isActive: true,
      companyName: 'Ram Enterprises',
    );

    // Pass argument via constructor for isolated unit test
    await tester.pumpWidget(GetMaterialApp(
      home: UserDetailScreen(initialUser: testUser),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Ram Traders'), findsWidgets);
    expect(find.text('Profile, permissions & KYC verification'), findsOneWidget);

    // Verify Card Sections
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Company & Assignment'), findsOneWidget);
    expect(find.text('Account & System Details'), findsOneWidget);
    expect(find.text('Assigned Tags'), findsOneWidget);
    expect(find.text('KYC Details'), findsOneWidget);
    expect(find.text('Uploaded Documents'), findsOneWidget);
  });

  testWidgets('AddUserScreen renders HeroHeader, form cards and Create User button', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: AddUserScreen(),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Add User'), findsOneWidget);
    expect(find.text('Register platform member & assign permissions'), findsOneWidget);

    // Verify Header Card & Sections
    expect(find.text('Create Platform User'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Authentication'), findsOneWidget);

    // Verify Create User Button
    expect(find.text('Create User'), findsOneWidget);
  });

  testWidgets('ContractEditView renders HeroHeader, 3 cards and Save changes button', (tester) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final contract = ContractDetailModel.fromJson({
      'id': 101,
      'contract_id': 'CTR-2026-99',
      'product_title': 'Chana Desi',
      'product_category': 'Pulses',
      'buyer_name': 'Agro Mart',
      'buyer_unique_id': 'B-101',
      'seller_name': 'Kisan Traders',
      'seller_mapped_id': 'S-202',
      'deal_amount': '5500',
      'deal_quantity': '200',
      'amount_unit': 'qtl',
      'quantity_unit': 'qtl',
      'pickup_location': 'Indore',
      'delivery_location': 'Nagpur',
      'status': 'active',
    });

    await tester.pumpWidget(GetMaterialApp(
      home: ContractEditView(contract: contract),
    ));
    await tester.pump();

    // Verify HeroHeader
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Edit CTR-2026-99'), findsOneWidget);
    expect(find.text('Modify deal metrics, locations, schedule & remarks'), findsOneWidget);

    // Verify 3 Cards
    expect(find.text('Deal Parameters'), findsOneWidget);
    expect(find.text('Locations & Schedule'), findsOneWidget);
    expect(find.text('Status & Remarks'), findsOneWidget);

    // Verify Save button
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('AdminDrawer renders grouped cards with Dashboard, sections and Downloads', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(
        drawer: AdminDrawer(activeKey: 'dashboard'),
        body: Center(child: Text('Body')),
      ),
    ));
    await tester.pump();

    // Open drawer
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    // Verify AdminDrawer elements
    expect(find.byType(AdminDrawer), findsOneWidget);
    expect(find.text('ADMIN PANEL'), findsOneWidget);
    expect(find.text('OVERVIEW'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    // Scroll to bottom to verify Files & System section
    await tester.scrollUntilVisible(find.text('FILES & SYSTEM'), 200);
    expect(find.text('FILES & SYSTEM'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('TransportBidsSheet renders header with shipping icon and close button', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const GetMaterialApp(
      home: Scaffold(
        body: TransportBidsSheet(
          contractId: 101,
          contractNumber: 'JBC2611074575',
        ),
      ),
    ));
    await tester.pump();

    // Verify Header
    expect(find.text('Transport Bids'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
