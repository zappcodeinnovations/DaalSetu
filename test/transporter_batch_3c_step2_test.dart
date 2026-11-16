import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/branch/view/transporter_branch_view.dart';
import 'package:daalsetu/modules/transporter/branch/controller/transporter_branch_controller.dart';
import 'package:daalsetu/modules/transporter/branch/model/branch_model.dart';
import 'package:daalsetu/modules/transporter/users/view/transporter_users_view.dart';
import 'package:daalsetu/modules/users/controller/user_controller.dart';
import 'package:daalsetu/modules/users/model/user_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineBranchController extends TransporterBranchController {
  @override
  Future<void> fetchBranches({bool silent = false}) async {}
}

class _OfflineUserController extends UserController {
  @override
  Future<void> fetchUsers() async {}
}

BranchModel _createMockBranch() {
  return BranchModel(
    id: 1,
    locationName: "Nagpur Central Hub",
    state: "Maharashtra",
    city: "Nagpur",
    area: "MIDC Hingna",
    isActive: true,
    branchCode: "NAG622M",
  );
}

UserModel _createMockUser() {
  return UserModel(
    id: 101,
    username: "ramesh_transport",
    mobile: "9876543210",
    role: "transporter",
    firstName: "Ramesh",
    lastName: "Kumar",
    email: "ramesh@daalsetu.com",
    isActive: true,
    kycStatus: "approved",
    accountStatus: "active",
    tags: [],
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('TransporterBranchView renders HeroHeader, Join Banner, Branch Cards, and FAB', (tester) async {
    final branchCtrl = Get.put<TransporterBranchController>(_OfflineBranchController());
    branchCtrl.branches.assignAll([_createMockBranch()]);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: TransporterBranchView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('My Branches'), findsOneWidget);
    expect(find.text('Branch management & warehouses'), findsOneWidget);

    // Verify Join Banner
    expect(find.text('Join Existing Branch'), findsOneWidget);
    expect(find.text('Connect via reference code'), findsOneWidget);

    // Verify Branch Card
    expect(find.text('Nagpur Central Hub'), findsOneWidget);
    expect(find.text('MIDC Hingna, Nagpur, Maharashtra'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Code: NAG622M'), findsOneWidget);

    // Verify FAB
    expect(find.text('Enter Ref Code'), findsOneWidget);

    // Tap FAB to open Request Branch dialog
    await tester.tap(find.text('Enter Ref Code'));
    await tester.pumpAndSettle();

    expect(find.text('Request Branch'), findsOneWidget);
    expect(find.text('Submit Request'), findsOneWidget);
  });

  testWidgets('TransporterUsersView renders HeroHeader, Search, Role Filters, and User Cards', (tester) async {
    final userCtrl = Get.put<UserController>(_OfflineUserController());
    userCtrl.users.assignAll([_createMockUser()]);
    userCtrl.filteredUsers.assignAll([_createMockUser()]);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterUsersView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Network Users'), findsOneWidget);
    expect(find.text('Associated team & staff directory'), findsOneWidget);

    // Verify Search bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search by name, mobile, or email...'), findsOneWidget);

    // Verify Role Filter Pills
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Transporters'), findsOneWidget);
    expect(find.text('Salesmen'), findsOneWidget);

    // Verify User Card
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('TRANSPORTER'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });
}
