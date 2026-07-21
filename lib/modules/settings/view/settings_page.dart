import 'package:agro_broker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            /// PAGE TITLE
            Text(
              "Settings",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Manage your administrative preferences",
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),

            /// ACCOUNT SECTION
            _sectionLabel(context, "ACCOUNT"),
            _buildGroupedCard(context, [
              _buildTile(
                context,
                icon: Icons.person,
                title: "Profile",
                subtitle: "View and edit profile details",
                onTap: () {
                  Get.toNamed(AppRoutes.profile_page);
                },
              ),
              _buildDivider(context),
              _buildTile(
                context,
                icon: Icons.lock,
                title: "Change Password",
                subtitle: "Update your account password",
                onTap: () {
                  Get.toNamed(AppRoutes.change_password);
                },
              ),
            ]),

            const SizedBox(height: 30),

            /// APPEARANCE SECTION
            _sectionLabel(context, "APPEARANCE"),
            _buildGroupedCard(context, [
              Obx(
                () => _buildSwitchTile(
                  context,
                  icon: Icons.dark_mode,
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
            ]),

            const SizedBox(height: 30),

            /// APP INFO SECTION
            _sectionLabel(context, "APP INFORMATION"),
            _buildGroupedCard(context, [
              _buildTile(
                context,
                icon: Icons.info,
                title: "About App",
                onTap: () =>
                    _showInfoDialog(context, "About App", "Version 1.0"),
              ),
              _buildDivider(context),
              _buildTile(
                context,
                icon: Icons.description,
                title: "Terms & Conditions",
                onTap: () =>
                    _showInfoDialog(context, "Terms", "Details here..."),
              ),
              _buildDivider(context),
              _buildTile(
                context,
                icon: Icons.privacy_tip,
                title: "Privacy Policy",
                onTap: () =>
                    _showInfoDialog(context, "Privacy", "Details here..."),
              ),
            ]),

            const SizedBox(height: 30),

            /// SUPPORT
            _sectionLabel(context, "SUPPORT"),
            _buildGroupedCard(context, [
              _buildTile(
                context,
                icon: Icons.support_agent,
                title: "Help & Support",
                subtitle: "Contact support team",
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 40),

            /// LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  await AppPreferences.logout();
                  Get.offAll(() => LoginScreen());
                },
                child: const Text("Log Out"),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text("Version 1.0.0", style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  /// SECTION LABEL
  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// CARD CONTAINER
  Widget _buildGroupedCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 60,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: theme.textTheme.bodySmall)
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    Get.dialog(
      Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(content, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Close",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
