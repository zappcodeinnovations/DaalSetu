import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../seller/notifications/controller/seller_notification_controller.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class TransporterNotificationsView extends StatelessWidget {
  const TransporterNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerNotificationController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Notifications",
        subtitle: "Shipment alerts & trade updates",
        leading: AppBarLeading(
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.done_all, color: Colors.white),
          tooltip: "Mark all as read",
          onPressed: controller.markAllAsRead,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/thumb_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value && controller.notificationsList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
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
                      "You will be alerted when new loads or updates arrive.",
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchNotifications,
              color: primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.notificationsList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = controller.notificationsList[index];
                  final isRead = notif.isRead == true;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? (isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2))
                            : const Color(0xFFFFB300),
                        width: isRead ? 1.0 : 1.5,
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300).withValues(alpha: isRead ? 0.12 : 0.22),
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
                                notif.title ?? "Notification",
                                style: GoogleFonts.poppins(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (notif.message != null && notif.message!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  notif.message!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                              if (notif.timeAgo != null && notif.timeAgo!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  notif.timeAgo!,
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE65100),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
