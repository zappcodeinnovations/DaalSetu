import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../controller/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(ProfileController());

  // Colors mapped to active theme
  // Colors mapped to active theme
  Color get bgColor => Get.theme.scaffoldBackgroundColor;
  Color get cardColor => Get.theme.cardColor;
  Color get cardLighter => Get.isDarkMode ? const Color(0xFF1A2235) : const Color(0xFFF1F5F9);
  Color get textDark => Get.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get textLight => Get.isDarkMode ? const Color(0xFF8D96A7) : const Color(0xFF64748B);
  
  // Accents
  Color get accentGold => AppTheme.primaryGold;
  Color get accentGreen => AppTheme.successGreen;
  Color get accentBlue => AppTheme.secondaryOrange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconlyLight.arrow_left, color: Get.theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Admin Profile",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: textLight),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: accentGold),
          );
        }

        final user = controller.profile.value;

        if (user == null) {
          return Center(
            child: Text("No Data", style: TextStyle(color: textLight)),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchProfile,
          color: accentGold,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 24),

              _buildSectionTitle(context, Icons.person_outline, "GENERAL INFORMATION", showEdit: true),
              const SizedBox(height: 16),
              _buildGeneralInfoGrid(context, user),
              const SizedBox(height: 12),
              _buildFullWidthCard(
                context,
                icon: Icons.person,
                title: "Account Status",
                value: user.accountStatus.toLowerCase() == 'active' ? 'active' : user.accountStatus,
                valueColor: user.accountStatus.toLowerCase() == 'active' ? accentGreen : Colors.orange,
                trailing: Icon(Icons.check_circle_outline, color: accentGreen),
              ),

              const SizedBox(height: 28),

              _buildSectionTitle(context, Icons.work_outline, "COMPLIANCE & BUSINESS"),
              const SizedBox(height: 16),
              _buildFullWidthCard(
                context,
                icon: Icons.description_outlined,
                title: "GST Number",
                value: user.gstNumber.isEmpty ? "Not Available" : user.gstNumber,
                trailing: _buildBadge("Pending", accentGold, Icons.access_time),
              ),
              const SizedBox(height: 12),
              _buildManageCompanyCard(context),

              const SizedBox(height: 28),

              _buildSectionTitle(context, Icons.insert_drive_file_outlined, "DOCUMENTS"),
              const SizedBox(height: 16),
              
              _buildDocumentRow(
                context,
                title: "PAN Card",
                subtitle: "Verified • PDF (1.2 MB)",
                iconColor: accentGreen,
                iconText: "PAN",
              ),
              const SizedBox(height: 12),
              _buildDocumentRow(
                context,
                title: "GST Certificate",
                subtitle: "Verified • JPG (2.4 MB)",
                iconColor: accentBlue,
                iconText: "GST",
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }),
  );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.05) : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Glowing Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2312), // Dark gold base
              border: Border.all(color: accentGold.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accentGold.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: user.profileImage != null && user.profileImage!.isNotEmpty
                  ? Image.network(
                      user.profileImage!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(user),
                    )
                  : _buildInitialsAvatar(user),
            ),
          ),

          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${user.firstName} ${user.lastName}".trim().isEmpty
                      ? "Admin User"
                      : "${user.firstName} ${user.lastName}".trim(),
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: textLight,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPillBadge("ADMIN", accentGold, Icons.admin_panel_settings_outlined),
                    const SizedBox(width: 8),
                    _buildPillBadge("ACTIVE", accentGreen, Icons.circle, iconSize: 8),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(dynamic user) {
    return Center(
      child: Text(
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : "A",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
      ),
    );
  }

  Widget _buildPillBadge(String text, Color color, IconData icon, {double iconSize = 14}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title, {bool showEdit = false}) {
    return Row(
      children: [
        Icon(icon, color: accentGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (showEdit)
          InkWell(
            onTap: () async {
              await Get.toNamed(AppRoutes.editProfile);
              controller.fetchProfile();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cardLighter,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.05) : AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: accentGold, size: 12),
                  const SizedBox(width: 4),
                  Text("Edit", style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )
      ],
    );
  }

  Widget _buildGeneralInfoGrid(BuildContext context, dynamic user) {
    String displayGender = "Not Specified";
    if (user.gender.isNotEmpty) {
      displayGender = user.gender[0].toUpperCase() + user.gender.substring(1);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildGridItem(Icons.call, "Mobile Number", user.mobile.isEmpty ? "Not Provided" : user.mobile, const Color(0xFF6366F1))),
            const SizedBox(width: 12),
            Expanded(child: _buildGridItem(Icons.male, "Gender", displayGender, const Color(0xFF3B82F6))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGridItem(Icons.calendar_today, "Date of Birth", user.dob.isEmpty ? "Not Provided" : user.dob, accentGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildGridItem(Icons.badge_outlined, "PAN Number", user.panNumber.isEmpty ? "Not Provided" : user.panNumber, const Color(0xFFF97316))),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String title, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.05) : AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardLighter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textLight, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.05) : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardLighter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 18), // Purple icon for Account Status/GST
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textLight, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildManageCompanyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141310), // Very dark warm grey
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentGold.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.sellerCompany),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.domain, color: accentGold, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Manage Company", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text("Register a company or edit\nyour company details", style: TextStyle(color: textLight, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color iconColor,
    required String iconText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.05) : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                iconText,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Using RichText to make 'Verified' green and the rest grey
                RichText(
                  text: TextSpan(
                    text: subtitle.split(' • ')[0],
                    style: TextStyle(color: accentGreen, fontSize: 11, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: " • ${subtitle.split(' • ')[1]}",
                        style: TextStyle(color: textLight, fontSize: 11),
                      )
                    ]
                  )
                )
              ],
            ),
          ),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cardLighter,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.1) : AppTheme.borderLight),
            ),
            child: Center(child: Text("View", style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500))),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cardLighter,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Get.isDarkMode ? Colors.white.withOpacity(0.1) : AppTheme.borderLight),
            ),
            child: Icon(Icons.file_download_outlined, color: textDark, size: 16),
          ),
        ],
      ),
    );
  }
}
