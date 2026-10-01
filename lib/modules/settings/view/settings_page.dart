import 'dart:ui';
import 'package:iconly/iconly.dart';
import 'package:agro_broker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_broker/theme/glass_widgets.dart';
import '../../../theme/theme_controller.dart';
import '../../../utils/app_preferences.dart';
import '../../Auth/login/view/login_screen.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import 'package:agro_broker/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AdminDrawer(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            /// PAGE TITLE
            Text(
              "Settings",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Manage your administrative preferences",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 28),

            /// ACCOUNT SECTION
            _sectionLabel(context, "ACCOUNT"),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildTile(
                    context,
                    icon: IconlyLight.profile,
                    title: "Profile",
                    subtitle: "View and edit profile details",
                    onTap: () => Get.toNamed(AppRoutes.profile_page),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.work,
                    title: "Register Company",
                    subtitle: "Add or update your company profile",
                    onTap: () => Get.toNamed(AppRoutes.sellerCompany),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.lock,
                    title: "Change Password",
                    subtitle: "Update your account password",
                    onTap: () => Get.toNamed(AppRoutes.change_password),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            /// APP INFO
            _sectionLabel(context, "APP INFORMATION"),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildTile(
                    context,
                    icon: IconlyLight.info_square,
                    title: "About App",
                    onTap: () => _showInfoDialog(
                      context,
                      "About App",
                      "DaalSetu Admin v1.0",
                    ),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.document,
                    title: "Terms & Conditions",
                    onTap: () =>
                        _showInfoDialog(context, "Terms", "Details here..."),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.shield_done,
                    title: "Privacy Policy",
                    onTap: () =>
                        _showInfoDialog(context, "Privacy", "Details here..."),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            /// SUPPORT
            _sectionLabel(context, "SUPPORT"),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: _buildTile(
                context,
                icon: IconlyLight.call,
                title: "Help & Support",
                subtitle: "Contact support team",
                onTap: () {},
              ),
            ),

            const SizedBox(height: 32),

            /// LOGOUT BUTTON
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await AppPreferences.logout();
                    Get.offAllNamed(AppRoutes.login);
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          IconlyLight.logout,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Log Out",
                          style: GoogleFonts.poppins(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                "Version 1.0.0",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 80), // Space for floating nav bar
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }

  Widget _glassDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 64,
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GlassIconBox(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                IconlyLight.arrow_right_2,
                size: 16,
                color: theme.iconTheme.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GlassIconBox(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.borderColor,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        "Close",
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
