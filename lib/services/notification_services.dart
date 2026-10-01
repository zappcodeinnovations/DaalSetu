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
    final response = await ApiClient.get(
      endpoint: ApiUrls.notificationsUnreadCount,
      requireAuth: true,
    );
    if (response is Map<String, dynamic> && response["success"] == true) {
      final count = response["unread_count"];
      return count is int ? count : (int.tryParse(count?.toString() ?? '0') ?? 0);
    }
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
