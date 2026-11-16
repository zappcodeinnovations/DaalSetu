import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ambient Top Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFFE65100).withValues(alpha: 0.22),
                          const Color(0xFFF57C00).withValues(alpha: 0.10),
                          Colors.transparent,
                        ]
                      : [
                          const Color(0xFFFFE0B2).withValues(alpha: 0.65),
                          const Color(0xFFFFF3E0).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Glow Orbs
          Positioned(
            top: -100,
            right: -80,
            child: _Glow(
              size: 260,
              color: const Color(0xFFFFB300),
              isDark: isDark,
            ),
          ),
          Positioned(
            bottom: -90,
            left: -90,
            child: _Glow(
              size: 240,
              color: const Color(0xFFFF6D00),
              isDark: isDark,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Button & Navigation
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          tooltip: 'Back',
                          onPressed: () => Get.back(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Brand Logo & Platform Badge
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.7),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.30),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_icon.jpeg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DaalSetu',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: theme.textTheme.headlineMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2010) : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 13, color: Color(0xFFE65100)),
                            const SizedBox(width: 4),
                            Text(
                              "KISOR",
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "• Pulse Trading Platform",
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Reset Password Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Reset Password",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Enter your registered email address. Password instructions will be dispatched to your inbox.",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Email Field
                            TextField(
                              controller: controller.emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "Email Address",
                                labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                hintText: "Enter registered email",
                                prefixIcon: const Icon(IconlyLight.message, color: Color(0xFFFFB300), size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF282828) : const Color(0xFFFAFAFA),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Send Password Button
                            Obx(() {
                              final loading = controller.isLoading.value;
                              return Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: loading ? null : controller.submitForgotPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          "SEND PASSWORD",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Back to login button
                      TextButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.secondaryOrange),
                        label: Text(
                          "Back to Sign In",
                          style: GoogleFonts.inter(
                            color: AppTheme.secondaryOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final bool isDark;

  const _Glow({
    required this.size,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.22 : 0.16),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
