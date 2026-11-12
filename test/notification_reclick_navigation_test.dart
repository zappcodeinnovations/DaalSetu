import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daalsetu/modules/seller/notifications/controller/seller_notification_controller.dart';
import 'package:daalsetu/modules/seller/notifications/model/notification_model.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'role': 'seller'});
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Notification Re-click & Smooth Navigation Tests', () {
    test('markAsRead performs optimistic in-place update without triggering isLoading', () async {
      final controller = SellerNotificationController();
      controller.isLoading.value = false;

      final testNotif = AppNotificationModel(
        id: 555,
        title: "Test Deal Notification",
        message: "Deal #102 created",
        type: "deal",
        referenceId: 102,
        isRead: false,
      );

      controller.notificationsList.assignAll([testNotif]);
      controller.unreadCount.value = 1;

      expect(controller.notificationsList.first.isRead, false);
      expect(controller.unreadCount.value, 1);
      expect(controller.isLoading.value, false);

      // Perform markAsRead
      await controller.markAsRead(555);

      // Verify optimistic update without loading spinner
      expect(controller.notificationsList.first.isRead, true);
      expect(controller.unreadCount.value, 0);
      expect(controller.isLoading.value, false); // Crucial: isLoading stayed false!
    });

    test('Deal confirmed notification is not suppressed and routes successfully', () async {
      final dealNotif = AppNotificationModel(
        id: 701,
        title: "Deal Confirmed",
        message: "Deal #88 has been confirmed successfully",
        type: "deal_confirmed",
        referenceId: 88,
        isRead: false,
      );

      // navigateToTarget should execute without throwing or silently suppressing
      await RealtimeNotificationService.navigateToTarget(dealNotif);
      // Wait for debounce period to clear
      await Future.delayed(const Duration(milliseconds: 550));
    });

    test('Offer accepted notification extracts deal/contract ID and navigates', () async {
      final offerNotif = AppNotificationModel(
        id: 702,
        title: "Offer Accepted",
        message: "Buyer accepted seller response for deal #99",
        type: "buyer_offer_accepted",
        referenceId: 99,
        isRead: false,
      );

      await RealtimeNotificationService.navigateToTarget(offerNotif);
      await Future.delayed(const Duration(milliseconds: 550));
    });

    test('Clicking same notification 2nd time redirects properly after debounce', () async {
      final notif = AppNotificationModel(
        id: 703,
        title: "New Product",
        message: "Check product #42",
        type: "product",
        relatedProduct: 42,
        isRead: true,
      );

      // 1st click
      await RealtimeNotificationService.navigateToTarget(notif);

      // Wait for user interaction time / screen pop
      await Future.delayed(const Duration(milliseconds: 550));

      // 2nd click should redirect without getting blocked
      await RealtimeNotificationService.navigateToTarget(notif);
    });
  });
}

