import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modules/seller/notifications/model/notification_model.dart';
import '../modules/seller/notifications/view/seller_notification_view.dart';
import '../modules/products/view/product_detail.dart';
import '../utils/app_preferences.dart';
import 'notification_services.dart';

class RealtimeNotificationService extends GetxService {
  static RealtimeNotificationService get to => Get.find<RealtimeNotificationService>();

  Timer? _pollingTimer;
  final Set<int> _knownNotificationIds = {};
  bool _isInitialized = false;

  final RxInt unreadCount = 0.obs;
  final RxList<AppNotificationModel> latestNotifications = <AppNotificationModel>[].obs;
  final RxBool isPolling = false.obs;

  static const String _seenIdsPrefKey = "seen_realtime_notification_ids";

  @override
  void onInit() {
    super.onInit();
    _loadSeenIdsFromStorage();
    startPolling();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  /// Start polling every 8 seconds
  void startPolling() {
    stopPolling();
    isPolling.value = true;
    _checkNotifications(); // Immediate first check
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _checkNotifications();
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    isPolling.value = false;
  }

  /// Manual refresh
  Future<void> refreshNow() async {
    await _checkNotifications();
  }

  /// Load persisted seen notification IDs from SharedPreferences
  Future<void> _loadSeenIdsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_seenIdsPrefKey) ?? [];
      _knownNotificationIds.addAll(list.map((e) => int.tryParse(e)).whereType<int>());
    } catch (_) {}
  }

  /// Save known notification IDs to SharedPreferences
  Future<void> _saveSeenIdsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsToSave = _knownNotificationIds.toList();
      if (idsToSave.length > 200) {
        idsToSave.removeRange(0, idsToSave.length - 200);
      }
      await prefs.setStringList(_seenIdsPrefKey, idsToSave.map((e) => e.toString()).toList());
    } catch (_) {}
  }

  /// Check notifications from API
  Future<void> _checkNotifications() async {
    try {
      final token = await AppPreferences.getAccessToken();
      if (token == null || token.isEmpty) {
        return;
      }

      // 1. Fetch latest notifications
      final res = await NotificationServices.getNotifications(page: 1, pageSize: 10);
      final rawList = (res['results'] as List?) ?? [];
      final items = rawList.map((e) => AppNotificationModel.fromJson(e)).toList();

      latestNotifications.assignAll(items);

      // 2. Fetch unread count from API and cross-check
      try {
        final count = await NotificationServices.getUnreadCount();
        unreadCount.value = count;
      } catch (_) {
        unreadCount.value = items.where((n) => n.isRead == false).length;
      }

      // If all latest notifications are read, force count to 0 if API is out of sync
      if (items.isNotEmpty && items.every((n) => n.isRead == true)) {
        unreadCount.value = 0;
      }

      if (!_isInitialized) {
        // First run: seed known IDs so cold start doesn't spam toasts for past history
        for (var n in items) {
          if (n.id != null) {
            _knownNotificationIds.add(n.id!);
          }
        }
        await _saveSeenIdsToStorage();
        _isInitialized = true;
        return;
      }

      // Check for newly arrived notifications
      final List<AppNotificationModel> newNotifications = [];
      for (var n in items) {
        if (n.id != null && !_knownNotificationIds.contains(n.id!)) {
          _knownNotificationIds.add(n.id!);
          newNotifications.add(n);
        }
      }

      if (newNotifications.isNotEmpty) {
        await _saveSeenIdsToStorage();
        // Show banner for each new notification
        for (var newNotif in newNotifications.reversed) {
          showNotificationPopup(newNotif);
        }
      }
    } catch (_) {
      // Keep silent for background polling
    }
  }

  /// Show floating real-time banner on top of the screen
  static void showNotificationPopup(AppNotificationModel notification) {
    final title = (notification.title ?? "New Notification").trim();
    final message = (notification.message ?? "").trim();
    final timeAgo = (notification.timeAgo ?? "Just now").trim();

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: EdgeInsets.zero,
      borderRadius: 18,
      duration: const Duration(seconds: 5),
      isDismissible: true,
      animationDuration: const Duration(milliseconds: 350),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      messageText: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E2616), const Color(0xFF1E1A12)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFFF59E0B)).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Get.closeCurrentSnackbar();
                  if (notification.id != null) {
                    NotificationServices.markAsRead(notification.id!);
                  }
                  if (notification.relatedProduct != null) {
                    Get.to(() => ProductDetailScreen(productId: notification.relatedProduct!));
                  } else {
                    Get.to(() => const SellerNotificationView());
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Golden/amber notification bell icon
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          IconlyBold.notification,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            if (message.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                message,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xFF451A03).withValues(alpha: 0.85),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Close button
                      InkWell(
                        onTap: () => Get.closeCurrentSnackbar(),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF92400E).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
