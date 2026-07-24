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

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    icon: IconlyLight.lock,
                    title: "Change Password",
                    subtitle: "Update your account password",
                    onTap: () => Get.toNamed(AppRoutes.change_password),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            /// APPEARANCE
            _sectionLabel(context, "APPEARANCE"),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Obx(
                () => _buildSwitchTile(
                  context,
                  icon: theme.brightness == Brightness.dark
                      ? IconlyLight.hide
                      : IconlyLight.show,
                  title: "Dark Mode",
                  subtitle: "Enable dark theme",
                  value: themeController.themeMode.value == ThemeMode.dark,
                  onChanged: (val) {
                    if (val) {
                      themeController.setDarkTheme();
                    } else {
                      themeController.setLightTheme();
                    }
                  },
                ),
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
                        context, "About App", "DaalSetu Admin v1.0"),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.document,
                    title: "Terms & Conditions",
                    onTap: () => _showInfoDialog(
                        context, "Terms", "Details here..."),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.shield_done,
                    title: "Privacy Policy",
                    onTap: () => _showInfoDialog(
                        context, "Privacy", "Details here..."),
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
                    Get.offAll(() => LoginScreen());
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
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

    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: GlassIconBox(icon: icon),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          : null,
      trailing: Icon(
        IconlyLight.arrow_right_2,
        size: 16,
        color: theme.iconTheme.color,
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

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: GlassIconBox(icon: icon),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  void _showInfoDialog(
      BuildContext context, String title, String content) {
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
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
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
