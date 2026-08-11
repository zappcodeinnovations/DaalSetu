import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daalsetu/theme/glass_widgets.dart';
import '../controller/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final ForgotPasswordController controller = Get.put(
    ForgotPasswordController(),
  );

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
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                      theme.colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
                          "Forgot Password",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),

                          Text(
                            "Reset Your Password",
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Enter your registered email address. If the account exists, password will be sent.",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Glass Form Card
                          GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                GlassTextField(
                                  controller: controller.emailController,
                                  hintText: "Email address",
                                  prefixIcon: IconlyLight.message,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 24),

                                Obx(
                                  () => GlassButton(
                                    isLoading: controller.isLoading.value,
                                    onPressed:
                                        controller.submitForgotPassword,
                                    gradientColors: [
                                      theme.colorScheme.primary,
                                      const Color(0xFFFF8F00),
                                    ],
                                    child: Text(
                                      "Send Password",
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

                          const SizedBox(height: 24),

                          Center(
                            child: TextButton(
                              onPressed: () => Get.back(),
                              child: Text(
                                "Back to Login",
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
