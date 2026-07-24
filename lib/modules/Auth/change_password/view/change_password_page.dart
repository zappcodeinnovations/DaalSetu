import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agro_broker/theme/glass_widgets.dart';
import '../controller/change_password_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key});

  final controller = Get.put(ChangePasswordController());

  final RxBool _isOldPassHidden = true.obs;
  final RxBool _isNewPassHidden = true.obs;
  final RxBool _isConfirmPassHidden = true.obs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1206), const Color(0xFF0D1117)]
                : [const Color(0xFFFFF8E1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        IconlyLight.arrow_left_2,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Text(
                      "Change Password",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Please enter your current password and your new desired password to update your account security.",
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Glass Form Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordField(
                              context: context,
                              label: "Old Password",
                              hint: "Enter old password",
                              controller: controller.oldPasswordController,
                              obscureText: _isOldPassHidden,
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              context: context,
                              label: "New Password",
                              hint: "Enter new password",
                              controller: controller.newPasswordController,
                              obscureText: _isNewPassHidden,
                            ),
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              context: context,
                              label: "Confirm Password",
                              hint: "Confirm new password",
                              controller:
                                  controller.confirmPasswordController,
                              obscureText: _isConfirmPassHidden,
                            ),
                            const SizedBox(height: 16),

                            // Tip
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    IconlyLight.info_square,
                                    color: theme.colorScheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Use at least 8 characters with letters, numbers, and symbols.",
                                      style: GoogleFonts.inter(
                                        color: theme
                                            .textTheme.bodyMedium?.color,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Button
                            Obx(
                              () => GlassButton(
                                isLoading: controller.isLoading.value,
                                onPressed: controller.changePassword,
                                gradientColors: [
                                  theme.colorScheme.primary,
                                  const Color(0xFFFF8F00),
                                ],
                                child: Text(
                                  "Update Password",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required RxBool obscureText,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => GlassTextField(
            controller: controller,
            obscureText: obscureText.value,
            hintText: hint,
            prefixIcon: IconlyLight.lock,
            suffixIcon: IconButton(
              icon: Icon(
                obscureText.value ? IconlyLight.show : IconlyLight.hide,
                color: theme.textTheme.bodyMedium?.color,
                size: 20,
              ),
              onPressed: () => obscureText.value = !obscureText.value,
            ),
          ),
        ),
      ],
    );
  }
}
