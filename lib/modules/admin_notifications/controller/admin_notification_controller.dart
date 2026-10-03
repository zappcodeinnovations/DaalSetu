import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/notification_services.dart';
import '../model/admin_notification_model.dart';

class AdminNotificationController extends GetxController {
  // ── Observables ──────────────────────────────────────────────────────────
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final unreadCount = 0.obs;

  final notifications = <AdminNotificationModel>[].obs;
  final filteredNotifications = <AdminNotificationModel>[].obs;

  final selectedFilter = 'All'.obs;
  final searchQuery = ''.obs;

  int _currentPage = 1;
  final int _pageSize = 15;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    debugPrint("🔔 [ADMIN NOTIFICATIONS] Initializing Controller...");
    fetchNotifications();
    fetchUnreadCount();

    // Scroll listener for pagination
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        if (!isLoading.value && !isLoadingMore.value && hasMore.value) {
          loadMore();
        }
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  // ── Fetch Notifications ──────────────────────────────────────────────────
  Future<void> fetchNotifications({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        isRefreshing.value = true;
        _currentPage = 1;
        hasMore.value = true;
      } else {
        isLoading.value = true;
        _currentPage = 1;
      }

      debugPrint("🔔 [ADMIN NOTIFICATIONS] Fetching notifications from server (Page: $_currentPage)...");

      final res = await NotificationServices.getNotifications(
        page: _currentPage,
        pageSize: _pageSize,
      );

      debugPrint("🔔 [ADMIN NOTIFICATIONS] Server raw response: $res");

      List rawList = [];
      if (res.containsKey('results') && res['results'] is List) {
        rawList = res['results'];
      } else if (res.containsKey('data') && res['data'] is List) {
        rawList = res['data'];
      } else if (res.containsKey('notifications') && res['notifications'] is List) {
        rawList = res['notifications'];
      }

      final parsedList = rawList
          .map((item) => AdminNotificationModel.fromJson(item is Map<String, dynamic> ? item : {}))
          .toList();

      notifications.assignAll(parsedList);

      if (parsedList.length < _pageSize) {
        hasMore.value = false;
      }

      // Sync unread count
      if (res.containsKey('unread_count')) {
        final rawCount = res['unread_count'];
        unreadCount.value = rawCount is int ? rawCount : (int.tryParse(rawCount?.toString() ?? '0') ?? 0);
      } else {
        await fetchUnreadCount();
      }

      applyFilters();

      debugPrint("✅ [ADMIN NOTIFICATIONS] Successfully loaded ${notifications.length} notifications. Unread: ${unreadCount.value}");
    } catch (e) {
      debugPrint("❌ [ADMIN NOTIFICATIONS] Error fetching notifications: $e");
      Get.snackbar(
        "Notice",
        "Could not load notifications. Please pull down to refresh.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.info_outline, color: Color(0xFFF5B400)),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Load More (Pagination) ───────────────────────────────────────────────
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      final nextPage = _currentPage + 1;
      debugPrint("🔔 [ADMIN NOTIFICATIONS] Loading more notifications (Page: $nextPage)...");

      final res = await NotificationServices.getNotifications(
        page: nextPage,
        pageSize: _pageSize,
      );

      List rawList = [];
      if (res.containsKey('results') && res['results'] is List) {
        rawList = res['results'];
      } else if (res.containsKey('data') && res['data'] is List) {
        rawList = res['data'];
      }

      final parsed = rawList
          .map((item) => AdminNotificationModel.fromJson(item is Map<String, dynamic> ? item : {}))
          .toList();

      if (parsed.isEmpty) {
        hasMore.value = false;
      } else {
        _currentPage = nextPage;
        notifications.addAll(parsed);
        if (parsed.length < _pageSize) {
          hasMore.value = false;
        }
        applyFilters();
      }

      debugPrint("✅ [ADMIN NOTIFICATIONS] Appended ${parsed.length} more notifications. Total: ${notifications.length}");
    } catch (e) {
      debugPrint("❌ [ADMIN NOTIFICATIONS] Error loading more: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ── Fetch Unread Count ───────────────────────────────────────────────────
  Future<void> fetchUnreadCount() async {
    try {
      final count = await NotificationServices.getUnreadCount();
      unreadCount.value = count;
      debugPrint("🔔 [ADMIN NOTIFICATIONS] Live unread count: $count");
    } catch (e) {
      debugPrint("⚠️ [ADMIN NOTIFICATIONS] Error fetching unread count: $e");
    }
  }

  // ── Mark Single As Read ──────────────────────────────────────────────────
  Future<void> markAsRead(AdminNotificationModel item) async {
    if (item.isRead) return;

    // Optimistic UI update
    item.isRead = true;
    notifications.refresh();
    filteredNotifications.refresh();
    if (unreadCount.value > 0) {
      unreadCount.value--;
    }

    try {
      debugPrint("🔔 [ADMIN NOTIFICATIONS] Marking Notification #${item.id} as read on server...");
      await NotificationServices.markAsRead(item.id);
      debugPrint("✅ [ADMIN NOTIFICATIONS] Notification #${item.id} marked as read.");
    } catch (e) {
      debugPrint("⚠️ [ADMIN NOTIFICATIONS] Error marking as read on server: $e");
    }
  }

  // ── Mark All As Read ─────────────────────────────────────────────────────
  Future<void> markAllAsRead() async {
    if (notifications.isEmpty || unreadCount.value == 0) {
      Get.snackbar(
        "Notice",
        "All notifications are already marked as read.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.info_outline, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Optimistic UI update
    for (var n in notifications) {
      n.isRead = true;
    }
    unreadCount.value = 0;
    notifications.refresh();
    filteredNotifications.refresh();

    try {
      debugPrint("🔔 [ADMIN NOTIFICATIONS] Marking all notifications as read...");
      await NotificationServices.markAllAsRead();

      Get.snackbar(
        "Success",
        "All notifications marked as read.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.done_all_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
      debugPrint("✅ [ADMIN NOTIFICATIONS] All notifications marked as read successfully.");
    } catch (e) {
      debugPrint("❌ [ADMIN NOTIFICATIONS] Error marking all as read: $e");
      Get.snackbar(
        "Error",
        "Failed to mark all as read. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      // Re-fetch to restore actual state
      fetchNotifications(isRefresh: true);
    }
  }

  // ── Filter Selection ─────────────────────────────────────────────────────
  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query.trim().toLowerCase();
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilters();
  }

  void applyFilters() {
    var list = notifications.toList();

    // Filter by Tab
    if (selectedFilter.value == 'Unread') {
      list = list.where((n) => !n.isRead).toList();
    } else if (selectedFilter.value == 'Trades') {
      list = list.where((n) {
        final t = n.type.toLowerCase();
        return t.contains('contract') || t.contains('deal') || t.contains('challan') || t.contains('offer');
      }).toList();
    } else if (selectedFilter.value == 'System') {
      list = list.where((n) {
        final t = n.type.toLowerCase();
        return t.contains('kyc') || t.contains('system') || t.contains('rfq');
      }).toList();
    }

    // Filter by Search Query
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value;
      list = list.where((n) {
        final titleMatch = n.title.toLowerCase().contains(q);
        final msgMatch = n.message.toLowerCase().contains(q);
        final typeMatch = n.type.toLowerCase().contains(q);
        return titleMatch || msgMatch || typeMatch;
      }).toList();
    }

    filteredNotifications.assignAll(list);
  }

  // ── Smart Tap Navigation ─────────────────────────────────────────────────
  void handleNotificationTap(AdminNotificationModel item) {
    markAsRead(item);

    final t = item.type.toLowerCase();
    final url = (item.redirectUrl ?? '').toLowerCase();

    debugPrint("🔔 [ADMIN NOTIFICATIONS] Tapped on #${item.id} (Type: $t, Ref: ${item.referenceId}, Url: $url)");

    if (t.contains('challan') || url.contains('challan') || t.contains('consignment')) {
      Get.toNamed(AppRoutes.adminDeliveryChallans);
    } else {
      // General or trade notification info preview
      Get.bottomSheet(
        _buildNotificationDetailSheet(item),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  Widget _buildNotificationDetailSheet(AdminNotificationModel item) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.iconData, color: item.accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      item.displayTime,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            item.message,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Get.back(),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }
}
