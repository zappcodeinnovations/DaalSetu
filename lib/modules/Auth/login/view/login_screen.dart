import 'dart:ui';
import 'package:iconly/iconly.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/glass_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/login_controller.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _rememberMe = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());
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
                ? [
                    const Color(0xFF2A1B00),
                    const Color(0xFF0D1117),
                  ]
                : [
                    const Color(0xFFFFF3CC),
                    const Color(0xFFFFFCF5),
                    Colors.white,
                  ],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative circles ──────────────────────────────
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.secondary.withValues(alpha: 0.1),
                      theme.colorScheme.secondary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main Content ─────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      // ── Logo with glass frame ─────────────────
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/app_icon.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Welcome Text ──────────────────────────
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Sign in to manage your platform",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Glass Form Card ───────────────────────
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        blur: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Admin ID
                            Text(
                              "Admin ID or Email",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GlassTextField(
                              controller: controller.usernameController,
                              hintText: "Enter your admin ID",
                              prefixIcon: IconlyLight.profile,
                              validator: (value) =>
                                  value!.isEmpty ? "Enter Admin ID" : null,
                            ),

                            const SizedBox(height: 22),

                            // Password Label + Forgot
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Password",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Get.toNamed(AppRoutes.forgot_password);
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: GoogleFonts.inter(
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Password Input
                            ValueListenableBuilder<bool>(
                              valueListenable: _isPasswordVisible,
                              builder: (context, isVisible, child) {
                                return GlassTextField(
                                  controller: controller.passwordController,
                                  obscureText: !isVisible,
                                  hintText: "••••••••",
                                  prefixIcon: IconlyLight.lock,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isVisible
                                          ? IconlyLight.show
                                          : IconlyLight.hide,
                                      color:
                                          theme.textTheme.bodyMedium?.color,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _isPasswordVisible.value = !isVisible;
                                    },
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? "Enter password"
                                      : null,
                                );
                              },
                            ),

                            const SizedBox(height: 18),

                            // Remember Me
                            Row(
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: _rememberMe,
                                  builder: (context, val, child) {
                                    return SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: Checkbox(
                                        value: val,
                                        onChanged: (value) =>
                                            _rememberMe.value = value!,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Remember this device",
                                  style: GoogleFonts.inter(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Sign In Button
                            Obx(
                              () => GlassButton(
                                isLoading: controller.isLoading.value,
                                onPressed: controller.login,
                                gradientColors: [
                                  theme.colorScheme.primary,
                                  const Color(0xFFFF8F00),
                                ],
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Sign In",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      IconlyLight.arrow_right_2,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () => Get.toNamed('/register'),
                        child: Text(
                          "Register New Account",
                          style: GoogleFonts.inter(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
