import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../theme/app_theme.dart';
import '../controller/admin_notification_controller.dart';
import '../model/admin_notification_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class AdminNotificationView extends StatelessWidget {
  const AdminNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminNotificationController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final cardBg = isDark ? AppTheme.cardColor : Colors.white;
    final borderColor = isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Notifications",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final count = controller.unreadCount.value;
              if (count <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Color(0xFFE65100),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }),
          ],
        ),
        subtitle: "Platform alerts & operational notices",
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Mark all as read",
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              onPressed: controller.markAllAsRead,
            ),
            IconButton(
              tooltip: "Refresh",
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () => controller.fetchNotifications(isRefresh: true),
            ),
          ],
        ),
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
                      child: CircularProgressIndicator(color: Color(0xFFFF9800)),
                    );
                  }

                  if (controller.filteredNotifications.isEmpty) {
                    return _buildEmptyState(controller, isDark);
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFFF9800),
                    onRefresh: () => controller.fetchNotifications(isRefresh: true),
                    child: ListView.separated(
                      controller: controller.scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                                  color: Color(0xFFFF9800),
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
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(IconlyLight.search, color: Color(0xFFFF9800), size: 18),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: controller.clearSearch,
                    )
                  : const SizedBox.shrink()),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.8),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? AppTheme.cardColor : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2)),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (highlightBadge ? const Color(0xFFFF9800) : (isDark ? Colors.black26 : const Color(0xFFFFF3E0))),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (highlightBadge ? Colors.white : const Color(0xFFE65100)),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
        ? (isDark ? const Color(0xFF2A2118) : const Color(0xFFFFFBEB))
        : cardBg;

    return InkWell(
      onTap: () => controller.handleNotificationTap(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? const Color(0xFFFF9800) : borderColor,
            width: isUnread ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.iconData,
                color: item.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: item.accentColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Text(
                        item.displayTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(AdminNotificationController controller, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconlyLight.notification,
                size: 48,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? "No matching notifications"
                  : "No notifications yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? "Try adjusting your search or filters"
                  : "All caught up! New alerts will appear here.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
