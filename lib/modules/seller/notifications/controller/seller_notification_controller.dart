import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../../../../services/notification_services.dart';
import '../../../../services/realtime_notification_service.dart';
import '../../../../utils/app_snackbar.dart';

class SellerNotificationController extends GetxController {
  var isLoading = true.obs;
  var notificationsList = <AppNotificationModel>[].obs;
  var unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchUnreadCount();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading(true);
      final res = await NotificationServices.getNotifications();
      final rawList = (res['results'] is List)
          ? res['results'] as List
          : ((res['data'] is List)
              ? res['data'] as List
              : (res is List ? res as List : []));
      notificationsList.value = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => AppNotificationModel.fromJson(e))
          .toList();
    } catch (e) {
      // Keep quiet or log error
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await NotificationServices.getUnreadCount();
      unreadCount.value = count;
    } catch (_) {}
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      // Optimistic in-place update so the list does not reload or flicker
      final index = notificationsList.indexWhere((n) => n.id == notificationId);
      if (index != -1 && notificationsList[index].isRead != true) {
        final current = notificationsList[index];
        notificationsList[index] = AppNotificationModel(
          id: current.id,
          title: current.title,
          message: current.message,
          role: current.role,
          type: current.type,
          referenceId: current.referenceId,
          relatedProduct: current.relatedProduct,
          redirectUrl: current.redirectUrl,
          isRead: true,
          createdAt: current.createdAt,
          timeAgo: current.timeAgo,
        );
        notificationsList.refresh();
        if (unreadCount.value > 0) {
          unreadCount.value--;
        }
      }

      await NotificationServices.markAsRead(notificationId);
      if (Get.isRegistered<RealtimeNotificationService>()) {
        RealtimeNotificationService.to.refreshNow();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationServices.markAllAsRead();
      AppSnackbar.snackbar("Success", "All notifications marked as read", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchNotifications();
      fetchUnreadCount();
      if (Get.isRegistered<RealtimeNotificationService>()) {
        RealtimeNotificationService.to.refreshNow();
      }
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}

