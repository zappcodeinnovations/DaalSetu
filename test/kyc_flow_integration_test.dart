import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_detail_screen.dart';
import 'package:daalsetu/modules/kyc_users/controller/kyc_user_controller.dart';
import 'package:daalsetu/modules/kyc_users/model/kyc_user_model.dart';
import 'package:daalsetu/modules/kyc_users/view/kyc_user_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _OfflineKycController extends KycController {
  @override
  Future<void> fetchUsers({String? search, String? role, String? status}) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'admin'});
  });

  tearDown(Get.reset);

  group('KYC Drawer, Navigation & Review Integration Scenarios', () {
    testWidgets('Scenario 1: KYC screen renders 3 lines (hamburger menu) when on root and opens AdminDrawer', (tester) async {
      tester.view.physicalSize = const Size(450, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put<KycController>(_OfflineKycController());
      controller.isLoading.value = false;

      await tester.pumpWidget(GetMaterialApp(home: KycUsersScreen()));
      await tester.pumpAndSettle();

      // Verify the 3 lines menu icon is present
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byType(AdminDrawer), findsNothing);

      // Tap the 3 lines menu icon
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Drawer opens successfully
      expect(find.byType(AdminDrawer), findsOneWidget);
    });

    testWidgets('Scenario 2: KYC user card action buttons (Review, Approve, Reject, History) are all rendered', (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = Get.put<KycController>(_OfflineKycController());
      controller.isLoading.value = false;
      controller.kycUsers.assignAll([
        KycUserModel(
          id: 175,
          name: 'iuytgrfdsfdgfhjhk',
          mobile: '9875632147',
          email: 'h@gmail.com',
          role: 'buyer',
          kycStatus: 'pending',
          accountStatus: 'active',
          panNumber: 'ABCDE1234F',
          gstNumber: '27ABCDE1234F1Z5',
          kycSubmittedAt: '2026-11-19T10:00:00Z',
          kycApprovedAt: null,
          kycRejectedAt: null,
          kycRejectionReason: null,
        ),
      ]);

      await tester.pumpWidget(GetMaterialApp(home: KycUsersScreen()));
      await tester.pumpAndSettle();

      // Card content visible
      expect(find.text('iuytgrfdsfdgfhjhk'), findsWidgets);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Tap Reject button to open Rejection Reason modal
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Reject KYC'), findsOneWidget);
      expect(find.text('Enter rejection reason'), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter rejection reason'), findsNothing);
    });

    testWidgets('Scenario 3: Admin KYC Detail Review screen renders Approve KYC and Reject KYC with Rejection Reason modal', (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final kycConfig = AdminModules.byKey('kyc');
      final record = const AdminRecord({
        'id': 175,
        'name': 'iuytgrfdsfdgfhjhk',
        'username': 'iuytgrfdsfdgfhjhk',
        'mobile': '9875632147',
        'email': 'h@gmail.com',
        'role': 'buyer',
        'kyc_status': 'pending',
        'status': 'pending',
        'pan_number': 'ABCDE1234F',
        'gst_number': '27ABCDE1234F1Z5',
      });

      await tester.pumpWidget(GetMaterialApp(
        home: AdminRecordDetailScreen(
          config: kycConfig,
          record: record,
        ),
      ));
      await tester.pumpAndSettle();

      // Both action buttons exist at bottom of screen
      expect(find.widgetWithText(ElevatedButton, 'Approve'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reject'), findsOneWidget);

      // Tap Reject button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Reject'));
      await tester.pumpAndSettle();

      // Modal prompt appears requiring rejection reason
      expect(find.text('Reject'), findsWidgets);
      expect(find.text('Rejection Reason'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
