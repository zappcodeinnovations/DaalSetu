import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
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

                            // Dynamic Password Requirements Card
                            Obx(() {
                              final hasMinLength = controller.hasMinLength;
                              final hasLetter = controller.hasLetter;
                              final hasNumber = controller.hasNumber;
                              final hasSymbol = controller.hasSymbol;
                              final isAllValid = controller.isNewPasswordValid;

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isAllValid
                                      ? Colors.green.withValues(alpha: 0.08)
                                      : theme.colorScheme.primary
                                          .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAllValid
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isAllValid
                                              ? IconlyBold.shield_done
                                              : IconlyLight.info_square,
                                          color: isAllValid
                                              ? Colors.green
                                              : theme.colorScheme.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Password Requirements",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isAllValid
                                                ? Colors.green
                                                : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildRequirementItem(
                                      theme: theme,
                                      isValid: hasMinLength,
                                      text: "At least 8 characters",
                                    ),
                                    const SizedBox(height: 6),
                                    _buildRequirementItem(
                                      theme: theme,
                                      isValid: hasLetter,
                                      text: "Contains at least 1 letter (a-z, A-Z)",
                                    ),
                                    const SizedBox(height: 6),
                                    _buildRequirementItem(
                                      theme: theme,
                                      isValid: hasNumber,
                                      text: "Contains at least 1 number (0-9)",
                                    ),
                                    const SizedBox(height: 6),
                                    _buildRequirementItem(
                                      theme: theme,
                                      isValid: hasSymbol,
                                      text: "Contains at least 1 symbol (!@#\$%...)",
                                    ),
                                  ],
                                ),
                              );
                            }),

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

  Widget _buildRequirementItem({
    required ThemeData theme,
    required bool isValid,
    required String text,
  }) {
    final activeColor = const Color(0xFF2E7D32);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = isDark
        ? Colors.white38
        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
            Colors.grey;

    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 15,
          color: isValid ? activeColor : inactiveColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isValid ? FontWeight.w500 : FontWeight.w400,
            color: isValid ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }
}

