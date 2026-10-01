import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_notification_controller.dart';

class SellerNotificationView extends StatelessWidget {
  const SellerNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerNotificationController());
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Notifications", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: primaryColor),
            tooltip: "Mark all as read",
            onPressed: controller.markAllAsRead,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (controller.notificationsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.notification, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("No notifications", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          color: primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.notificationsList.length,
            itemBuilder: (context, index) {
              final item = controller.notificationsList[index];
              return Card(
                elevation: item.isRead == true ? 1 : 3,
                margin: const EdgeInsets.only(bottom: 12),
                color: item.isRead == true ? null : Colors.amber.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    child: const Icon(IconlyLight.notification, color: primaryColor),
                  ),
                  title: Text(
                    item.title ?? "Notification",
                    style: TextStyle(fontWeight: item.isRead == true ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(item.message ?? ''),
                  trailing: Text(
                    item.timeAgo ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () {
                    if (item.id != null && item.isRead != true) {
                      controller.markAsRead(item.id!);
                    }
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
