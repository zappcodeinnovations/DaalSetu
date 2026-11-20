import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../modules/profile/controller/profile_controller.dart';
import '../routes/app_routes.dart';

/// The round profile button on the right of every dashboard header: the user's real photo when they have one,
/// otherwise the plain person icon. Tapping it opens the profile page.
class HeaderProfileAvatar extends StatelessWidget {
  const HeaderProfileAvatar({super.key, this.radius = 15});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : Get.put(ProfileController());
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.profile_page),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        ),
        child: Obx(() {
          final url = controller.profileImageUrl(controller.profile.value?.profileImage);
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            foregroundImage: url.isEmpty ? null : NetworkImage(url),
            // Shown when there is no photo, and under the photo while it loads or if it cannot load.
            child: Icon(IconlyLight.user_1, size: radius + 1, color: const Color(0xFFE65100)),
          );
        }),
      ),
    );
  }
}
