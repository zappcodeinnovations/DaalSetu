import '../network/api_client.dart';
import '../comman/api_url.dart';

class NotificationServices {
  /// [silent] for background polling: a failed poll must not open the global server-error popup.
  static Future<Map<String, dynamic>> getNotifications({int page = 1, int pageSize = 10, bool silent = false}) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.notifications}?page=$page&page_size=$pageSize",
      requireAuth: true,
      suppressErrorDialog: silent,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to fetch notifications");
    }
    return response;
  }

  static Future<int> getUnreadCount({bool silent = false}) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.notificationsUnreadCount,
      requireAuth: true,
      suppressErrorDialog: silent,
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
