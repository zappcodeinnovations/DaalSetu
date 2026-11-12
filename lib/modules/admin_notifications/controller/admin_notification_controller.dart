import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../../services/notification_services.dart';
import '../../admin_catalog/view/offer_interests_dialog.dart';
import '../../kyc_users/view/kyc_user_view.dart';
import '../model/admin_notification_model.dart';
import '../../../utils/app_snackbar.dart';

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
    _setupPagination();
  }

  @override
  void onClose() {
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _setupPagination() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore.value &&
          hasMore.value) {
        loadMoreNotifications();
      }
    });
  }

  // ── Fetch Notifications (Initial or Refresh) ──────────────────────────────
  Future<void> fetchNotifications({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }

      _currentPage = 1;
      hasMore.value = true;

      debugPrint("🔔 [ADMIN NOTIFICATIONS] Fetching notifications from server (Page: 1)...");
      final response = await NotificationServices.getNotifications(
        page: 1,
        pageSize: _pageSize,
      );

      final rawList = (response['results'] is List)
          ? response['results'] as List
          : ((response['data'] is List) ? response['data'] as List : []);

      final parsed = rawList
          .map((item) => AdminNotificationModel.fromJson(item is Map<String, dynamic> ? item : {}))
          .toList();

      notifications.assignAll(parsed);
      applyFilters();

      // Check pagination boundary
      final totalCount = response['count'] ?? response['total'] ?? parsed.length;
      if (parsed.length >= (totalCount is int ? totalCount : parsed.length) || parsed.length < _pageSize) {
        hasMore.value = false;
      }

      debugPrint("✅ [ADMIN NOTIFICATIONS] Successfully loaded ${parsed.length} notifications. Unread: ${unreadCount.value}");
    } catch (e) {
      debugPrint("❌ [ADMIN NOTIFICATIONS] Error fetching notifications: $e");
      AppSnackbar.snackbar(
        "Notifications",
        "Failed to load notifications. Pull down to try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Load More Notifications (Infinite Scroll) ─────────────────────────────
  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      final nextPage = _currentPage + 1;
      debugPrint("🔔 [ADMIN NOTIFICATIONS] Loading page $nextPage...");

      final response = await NotificationServices.getNotifications(
        page: nextPage,
        pageSize: _pageSize,
      );

      final rawList = (response['results'] is List)
          ? response['results'] as List
          : ((response['data'] is List) ? response['data'] as List : []);

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
      final count = await NotificationServices.getUnreadCount(silent: true);
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
      AppSnackbar.snackbar(
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

      AppSnackbar.snackbar(
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
      AppSnackbar.snackbar(
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

  // ── Offer / Product ID Extractor ─────────────────────────────────────────
  int? extractOfferId(AdminNotificationModel item) {
    // 1. Check direct relatedProduct (e.g. from deal or contract)
    if (item.relatedProduct != null && item.relatedProduct! > 0) {
      return item.relatedProduct;
    }

    // 2. Check redirect_url for query params or path segments
    if (item.redirectUrl != null && item.redirectUrl!.isNotEmpty) {
      final url = item.redirectUrl!;
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final qOffer = uri.queryParameters['offer_id'] ??
            uri.queryParameters['product_id'] ??
            uri.queryParameters['productId'];
        if (qOffer != null) {
          final parsed = int.tryParse(qOffer);
          if (parsed != null && parsed > 0) return parsed;
        }

        final segments = uri.pathSegments;
        final offerIdx = segments.indexOf('offers');
        if (offerIdx != -1 && segments.length > offerIdx + 1) {
          final parsed = int.tryParse(segments[offerIdx + 1]);
          if (parsed != null && parsed > 0) return parsed;
        }
      }

      final match = RegExp(r'(?:offers\/|offer_id=|product_id=)(\d+)').firstMatch(url);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    // 3. Fallback for offer/deal types where referenceId points to offer
    final t = item.type.toLowerCase();
    if (t.contains('offer') || t.contains('deal') || t.contains('interest')) {
      if (item.referenceId != null && item.referenceId! > 0) {
        return item.referenceId;
      }
    }

    return null;
  }

  // ── Smart Tap Navigation ─────────────────────────────────────────────────
  void handleNotificationTap(AdminNotificationModel item) {
    markAsRead(item);

    final t = item.type.toLowerCase();
    final url = (item.redirectUrl ?? '').toLowerCase();
    final offerId = extractOfferId(item);

    debugPrint("🔔 [ADMIN NOTIFICATIONS] Tapped on #${item.id} (Type: $t, Ref: ${item.referenceId}, RelProd: ${item.relatedProduct}, ExtractedOffer: $offerId, Url: $url)");

    // 1. High Priority: If notification is linked to an Offer or Deal, open the detailed Offer Management Modal
    if (offerId != null) {
      openOfferManagementModal(offerId.toString(), title: item.title);
      return;
    }

    // 2. Delivery Challan / Consignment
    if (t.contains('challan') || url.contains('challan') || t.contains('consignment')) {
      Get.toNamed(AppRoutes.adminDeliveryChallans);
      return;
    }

    // 3. KYC Approval Verification
    if (t.contains('kyc') || url.contains('kyc') || url.contains('user')) {
      Get.to(() => KycUsersScreen());
      return;
    }

    // 4. Contract History
    if (t.contains('contract') || url.contains('contract')) {
      Get.toNamed(AppRoutes.adminContractHistory);
      return;
    }

    // 5. Fallback detail sheet
    Get.bottomSheet(
      _buildNotificationDetailSheet(item),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openOfferManagementModal(String offerId, {String? title}) {
    Get.dialog(
      OfferInterestsDialog(
        offerId: offerId,
        offerTitle: title ?? 'Offer #$offerId',
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildNotificationDetailSheet(AdminNotificationModel item) {
    final offerId = extractOfferId(item);

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

          // Action Button to direct admins to the Offer Management Modal
          if (offerId != null) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF58220),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.handshake_outlined),
                label: const Text(
                  "Manage Offer (Negotiation, Accept, Reject)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Get.back();
                  openOfferManagementModal(offerId.toString(), title: item.title);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
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
