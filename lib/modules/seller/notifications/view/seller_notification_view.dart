import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_notification_controller.dart';
import '../../../../services/realtime_notification_service.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class SellerNotificationView extends StatelessWidget {
  const SellerNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerNotificationController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFF57C00);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Notifications",
        subtitle: "Realtime updates & deal alerts",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.done_all_rounded, color: Colors.white),
          tooltip: "Mark all as read",
          onPressed: controller.markAllAsRead,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notificationsList.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (controller.notificationsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.notification, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No notifications yet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You will be alerted when new updates arrive.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          color: primaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notificationsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = controller.notificationsList[index];
              final isRead = item.isRead == true;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (item.id != null && !isRead) {
                    controller.markAsRead(item.id!);
                  }
                  RealtimeNotificationService.navigateToTarget(item);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isRead ? const Color(0xFF1E293B) : const Color(0xFF162032))
                        : (isRead ? Colors.white : const Color(0xFFFFFBF2)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? (isDark ? const Color(0xFF334155) : const Color(0xFFFFE0B2))
                          : const Color(0xFFF57C00),
                      width: isRead ? 1.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57C00).withValues(alpha: isRead ? 0.12 : 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRead ? IconlyLight.notification : IconlyBold.notification,
                          color: const Color(0xFFE65100),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title ?? "Notification",
                              style: GoogleFonts.poppins(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (item.message != null && item.message!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.message!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                            if (item.timeAgo != null && item.timeAgo!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.timeAgo!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 4, left: 6),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE65100),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
