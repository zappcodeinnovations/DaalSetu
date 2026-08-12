import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/glass_widgets.dart';
import '../controller/profile_controller.dart';
class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconlyLight.arrow_left, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Profile",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(IconlyLight.more_circle, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        final user = controller.profile.value;

        if (user == null) {
          return Center(
            child: Text("No Data", style: theme.textTheme.bodyLarge),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 30),

              _buildSectionTitle(context, "GENERAL INFORMATION"),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      "MOBILE NUMBER",
                      user.mobile,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInfoCard(context, "GENDER", user.gender),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(context, "DATE OF BIRTH", user.dob),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      "PAN NUMBER",
                      user.panNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildFullWidthCard(
                context,
                title: "ACCOUNT STATUS",
                value: user.accountStatus,
                trailing: Icon(
                  IconlyLight.tick_square,
                  color: theme.colorScheme.secondary,
                ),
              ),

              const SizedBox(height: 30),

              _buildSectionTitle(context, "COMPLIANCE & BUSINESS"),
              const SizedBox(height: 15),

              _buildFullWidthCard(
                context,
                title: "GST NUMBER",
                value: user.gstNumber,
              ),

              const SizedBox(height: 15),

              _buildKycStatusCard(context, user.kycStatus),

              const SizedBox(height: 30),

              _buildSectionTitle(context, "DOCUMENTS"),
              const SizedBox(height: 15),

              _buildDocumentCard(
                context,
                icon: IconlyLight.wallet,
                title: "PAN Card",
                subtitle: "Verified • PDF (1.2 MB)",
              ),

              const SizedBox(height: 15),

              _buildDocumentCard(
                context,
                icon: IconlyLight.document,
                title: "GST Certificate",
                subtitle: "Verified • JPG (2.4 MB)",
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
      // bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with glow effect
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Text(
                user.firstName[0].toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Full Name
          Text(
            "${user.firstName} ${user.lastName}",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // Email
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 20),

          // Role + Status Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChip(
                context,
                user.role.toUpperCase(),
                theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              _buildChip(context, "ACTIVE", theme.colorScheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelSmall ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(
    BuildContext context, {
    required String title,
    required String value,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildKycStatusCard(BuildContext context, String status) {
    final theme = Theme.of(context);

    bool approved =
        status.toLowerCase() == "approved" ||
        status.toLowerCase() == "verified";

    Color statusColor = approved ? theme.colorScheme.secondary : Colors.orange;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            approved ? IconlyLight.tick_square : IconlyLight.time_circle,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Text(
            status,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "View",
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(IconlyLight.edit, size: 18),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(IconlyLight.logout, size: 18),
              label: const Text("Logout"),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
