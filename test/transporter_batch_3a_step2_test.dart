import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/contracts/view/transporter_contracts_view.dart';
import 'package:daalsetu/modules/seller/contracts/controller/seller_contract_controller.dart';
import 'package:daalsetu/modules/transporter/notifications/view/transporter_notifications_view.dart';
import 'package:daalsetu/modules/seller/notifications/controller/seller_notification_controller.dart';
import 'package:daalsetu/modules/transporter/kyc/view/transporter_kyc_view.dart';
import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineContractController extends SellerContractController {
  @override
  Future<void> fetchContracts({bool silent = false}) async {}
}

class _OfflineNotificationController extends SellerNotificationController {
  @override
  Future<void> fetchNotifications({bool silent = false}) async {}
}

class _OfflineProfileController extends ProfileController {
  _OfflineProfileController() {
    isLoading.value = false;
  }

  @override
  Future<void> fetchProfile({bool showError = false, bool silent = false}) async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('TransporterContractsView renders HeroHeader and empty state or list', (tester) async {
    Get.put<SellerContractController>(_OfflineContractController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterContractsView()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Contracts'), findsOneWidget);
    expect(find.text('Assigned transit deals & trade agreements'), findsOneWidget);
    expect(find.byTooltip('Refresh'), findsOneWidget);
  });

  testWidgets('TransporterNotificationsView renders HeroHeader with mark all as read action', (tester) async {
    Get.put<SellerNotificationController>(_OfflineNotificationController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterNotificationsView()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Shipment alerts & trade updates'), findsOneWidget);
    expect(find.byTooltip('Mark all as read'), findsOneWidget);
  });

  testWidgets('TransporterKycView renders HeroHeader and KYC verification sections', (tester) async {
    Get.put<ProfileController>(_OfflineProfileController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterKycView()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('KYC Verification'), findsOneWidget);
    expect(find.text('Submitted KYC Documents'), findsOneWidget);
    expect(find.text('PAN Card'), findsOneWidget);
    expect(find.text('GST Registration'), findsOneWidget);
  });
}
