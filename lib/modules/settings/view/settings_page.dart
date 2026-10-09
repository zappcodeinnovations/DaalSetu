import 'dart:ui';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/glass_widgets.dart';
import '../../../theme/theme_controller.dart';
import '../../../utils/app_preferences.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import '../../admin_catalog/view/admin_module_list_screen.dart';
import '../../admin_catalog/view/admin_roles_screen.dart';
import '../../seller/common/seller_ui.dart';
import '../../../services/seller_services.dart';
import 'package:daalsetu/theme/app_theme.dart';

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
                  FutureBuilder<String?>(
                    future: AppPreferences.getRole(),
                    builder: (context, snapshot) {
                      const managerRoles = {
                        'super_admin',
                        'admin',
                        'seller',
                        'buyer',
                        'transporter',
                        'both_sellerandbuyer',
                      };
                      final role = (snapshot.data ?? '').toLowerCase();
                      if (!managerRoles.contains(role)) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _glassDivider(context),
                          _buildTile(
                            context,
                            icon: Icons.admin_panel_settings_outlined,
                            title: "Sub Admins",
                            subtitle: "Create and manage your team accounts",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminModuleListScreen(
                                  moduleKey: 'salesman',
                                  showAdminDrawer: false,
                                ),
                              ),
                            ),
                          ),
                          _glassDivider(context),
                          _buildTile(
                            context,
                            icon: Icons.badge_outlined,
                            title: "Roles",
                            subtitle: "Create and manage Sub Admin roles",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminRolesScreen(
                                  showAdminDrawer: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Re-approval request is only for party users; the server accepts it only for rejected KYC.
                  FutureBuilder<String?>(
                    future: AppPreferences.getRole(),
                    builder: (context, snapshot) {
                      const partyRoles = {'seller', 'buyer', 'transporter', 'both_sellerandbuyer'};
                      if (!partyRoles.contains(snapshot.data)) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _glassDivider(context),
                          _buildTile(
                            context,
                            icon: IconlyLight.shield_done,
                            title: "Request KYC Re-approval",
                            subtitle: "Ask admin to review your rejected KYC again",
                            onTap: () async {
                              final ok = await SellerUi.confirm(
                                "KYC Re-approval",
                                "Send your KYC to the admin for review again?",
                                confirmText: "Send Request",
                              );
                              if (ok) {
                                await SellerUi.run(SellerServices.requestKycApproval);
                              }
                            },
                          ),
                        ],
                      );
                    },
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
                  // _buildTile(
                  //   context,
                  //   icon: IconlyLight.info_square,
                  //   title: "About App",
                  //   onTap: () => _showInfoDialog(
                  //     context,
                  //     "About App",
                  //     "DaalSetu Admin v1.0",
                  //   ),
                  // ),
                  // _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.document,
                    title: "Terms & Conditions",
                    onTap: () => _showUrlDialog(
                      context,
                      "Terms & Conditions",
                      "https://www.daall-setu.com/terms-and-conditions/",
                    ),
                  ),
                  _glassDivider(context),
                  _buildTile(
                    context,
                    icon: IconlyLight.shield_done,
                    title: "Privacy Policy",
                    onTap: () => _showUrlDialog(
                      context,
                      "Privacy Policy",
                      "https://www.daall-setu.com/privacy-policy/",
                    ),
                  ),
                ],
              ),
            ),

            // const SizedBox(height: 26),
            // /// SUPPORT
            // _sectionLabel(context, "SUPPORT"),
            // const SizedBox(height: 10),
            // GlassCard(
            //   padding: EdgeInsets.zero,
            //   child: _buildTile(
            //     context,
            //     icon: IconlyLight.call,
            //     title: "Help & Support",
            //     subtitle: "Contact support team",
            //     onTap: () {},
            //   ),
            // ),

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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.borderColor : AppTheme.borderLight,
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

  void _showUrlDialog(BuildContext context, String title, String url) {
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.borderColor : AppTheme.borderLight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          IconlyLight.document,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Click Open to view the official $title in your browser:",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgSecondary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppTheme.borderColor : AppTheme.borderLight,
                      ),
                    ),
                    child: Text(
                      url,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                          _openUrl(url);
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text(
                          "Open",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not open link",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
