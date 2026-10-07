import '../network/api_client.dart';
import '../comman/api_url.dart';

class NotificationServices {
  static Future<Map<String, dynamic>> getNotifications({int page = 1, int pageSize = 10}) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.notifications}?page=$page&page_size=$pageSize",
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to fetch notifications");
    }
    return response;
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.notificationsUnreadCount,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response is Map<String, dynamic>) {
        final count = response["unread_count"] ??
            response["count"] ??
            (response["data"] is Map ? response["data"]["unread_count"] : null);
        if (count != null) {
          return count is int ? count : (int.tryParse(count.toString()) ?? 0);
        }
      }
    } catch (_) {}
    return 0;
  }

  static Future<void> markAsRead(int notificationId) async {
    await ApiClient.post(
      endpoint: ApiUrls.notificationsRead(notificationId),
      body: {},
      requireAuth: true,
    );
  }

  static Future<void> markAllAsRead() async {
    await ApiClient.post(
      endpoint: ApiUrls.notificationsReadAll,
      body: {},
      requireAuth: true,
    );
  }
}
