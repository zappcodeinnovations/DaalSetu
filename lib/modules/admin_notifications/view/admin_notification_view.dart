import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../theme/app_theme.dart';
import '../controller/admin_notification_controller.dart';
import '../model/admin_notification_model.dart';

class AdminNotificationView extends StatelessWidget {
  const AdminNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminNotificationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "Notifications",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final count = controller.unreadCount.value;
              if (count <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Mark all as read",
            icon: const Icon(Icons.done_all_rounded),
            onPressed: controller.markAllAsRead,
          ),
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchNotifications(isRefresh: true),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 720 : double.infinity),
          child: Column(
            children: [
              // ── Search & Filter Header ─────────────────────────────────────
              _buildFilterSection(controller, isDark, cardBg, borderColor),

              // ── Notification List ──────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGold),
                    );
                  }

                  if (controller.filteredNotifications.isEmpty) {
                    return _buildEmptyState(controller, isDark);
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGold,
                    onRefresh: () => controller.fetchNotifications(isRefresh: true),
                    child: ListView.separated(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: controller.filteredNotifications.length +
                          (controller.isLoadingMore.value ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == controller.filteredNotifications.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primaryGold,
                                ),
                              ),
                            ),
                          );
                        }

                        final item = controller.filteredNotifications[index];
                        return _buildNotificationCard(
                          context,
                          controller,
                          item,
                          isDark,
                          cardBg,
                          borderColor,
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search & Filter Bar ──────────────────────────────────────────────────
  Widget _buildFilterSection(
    AdminNotificationController controller,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search notifications...",
              prefixIcon: const Icon(IconlyLight.search, size: 18),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink()),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              final activeFilter = controller.selectedFilter.value;
              final unreadTotal = controller.unreadCount.value;

              return Row(
                children: [
                  _filterChip(
                    label: "All",
                    count: controller.notifications.length,
                    isSelected: activeFilter == 'All',
                    onTap: () => controller.setFilter('All'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "Unread",
                    count: unreadTotal,
                    isSelected: activeFilter == 'Unread',
                    onTap: () => controller.setFilter('Unread'),
                    isDark: isDark,
                    highlightBadge: unreadTotal > 0,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "Trades",
                    isSelected: activeFilter == 'Trades',
                    onTap: () => controller.setFilter('Trades'),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: "System",
                    isSelected: activeFilter == 'System',
                    onTap: () => controller.setFilter('System'),
                    isDark: isDark,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool highlightBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGold
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withValues(alpha: 0.15)
                      : (highlightBadge ? AppTheme.primaryGold : (isDark ? Colors.black26 : Colors.white)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.black
                        : (highlightBadge ? Colors.black : (isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Notification Card ────────────────────────────────────────────────────
  Widget _buildNotificationCard(
    BuildContext context,
    AdminNotificationController controller,
    AdminNotificationModel item,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    final isUnread = !item.isRead;
    final itemBg = isUnread
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB)) // Soft amber tint for unread
        : cardBg;

    return InkWell(
      onTap: () => controller.handleNotificationTap(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? AppTheme.primaryGold.withValues(alpha: 0.5) : borderColor,
            width: isUnread ? 1.4 : 1.0,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.iconData, color: item.accentColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.displayTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Unread Dot Indicator
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(AdminNotificationController controller, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyLight.notification,
                size: 56,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? "No matching notifications found"
                  : (controller.selectedFilter.value == 'Unread'
                      ? "You're all caught up!"
                      : "No notifications yet"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? "Try checking for typos or searching a different term."
                  : (controller.selectedFilter.value == 'Unread'
                      ? "There are no unread notifications right now."
                      : "New contracts, dispatches, and deal alerts will appear here."),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Refresh", style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => controller.fetchNotifications(isRefresh: true),
            ),
          ],
        ),
      ),
    );
  }
}
