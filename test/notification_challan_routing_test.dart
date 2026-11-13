import 'package:daalsetu/modules/seller/notifications/model/notification_model.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A "Dispatch Bill Uploaded" notification must open the challan, not a
/// "Contract details unavailable" page (its reference id is not a contract id).
void main() {
  Future<String> routeFor(WidgetTester tester, String role, AppNotificationModel notification) async {
    SharedPreferences.setMockInitialValues({'role': role});
    FlutterSecureStorage.setMockInitialValues({'user_role': role});
    Get.testMode = true;
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: Text('home'))));
    await tester.runAsync(() => RealtimeNotificationService.navigateToTarget(notification));
    await tester.pump();
    final route = Get.currentRoute;
    // leave the opened page before its controllers start polling
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 600));
    Get.reset();
    return route;
  }

  testWidgets('dispatch bill notification opens the buyer challan', (tester) async {
    final route = await routeFor(
      tester,
      'buyer',
      AppNotificationModel(
        id: 1,
        title: 'Dispatch Bill Uploaded',
        message: '1 bill file(s) added to delivery challan DC-1.',
        type: 'contract',
        referenceId: 7,
        redirectUrl: '/delivery-challan/7/',
        isRead: false,
      ),
    );
    expect(route, contains('BuyerDeliveryChallanDetailView'));
    expect(route, isNot(contains('ContractDetail')));
  });

  testWidgets('an offer-accepted (interest) notification is not opened as a contract', (tester) async {
    final route = await routeFor(
      tester,
      'buyer',
      AppNotificationModel(
        id: 2,
        title: 'Offer Accepted',
        message: 'Seller accepted your offer.',
        type: 'interest',
        referenceId: 55,
        isRead: false,
      ),
    );
    expect(route, isNot(contains('ContractDetail')));
  });
}
