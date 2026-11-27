import 'package:daalsetu/utils/mobile_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/login_controller.dart';
import 'widgets/login_art_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<LoginController>()) {
      final existing = Get.find<LoginController>();
      if (existing.isClosed) {
        Get.delete<LoginController>(force: true);
        controller = Get.put(LoginController());
      } else {
        controller = existing;
      }
    } else {
      controller = Get.put(LoginController());
    }
    final arguments = Get.arguments;
    if (arguments is Map && arguments['mobile'] != null) {
      controller.usernameController.text = arguments['mobile'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E2238);
    final subtextColor = isDark
        ? AppTheme.textSecondary
        : const Color(0xFF475569);
    final mutedColor = isDark ? AppTheme.textMuted : const Color(0xFF64748B);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFDFB),
        ),
        child: Stack(
          children: [
            // Exact background art: fluid curves & authentic wheat stalks watermark
            LoginArtBackground(isDark: isDark),

            // Top soft ambient golden halo behind logo
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFB74D).withValues(alpha: isDark ? 0.18 : 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _brandHeader(textColor, subtextColor, isDark),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2538).withValues(alpha: 0.96)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFFFB300).withValues(alpha: 0.22)
                                    : const Color(0xFFF1F5F9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(
                                    alpha: isDark ? 0.35 : 0.06,
                                  ),
                                  blurRadius: 26,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFF9800).withValues(
                                    alpha: isDark ? 0.06 : 0.03,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.30),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 12,
                                            color: Color(0xFF059669),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Encrypted',
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Use your registered mobile number to continue.',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Mobile field label with orange mobile icon
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_android_rounded,
                                      size: 16,
                                      color: Color(0xFFF57C00),
                                    ),
                                    const SizedBox(width: 7),
                                    _label('Mobile number', textColor),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                GlassTextField(
                                  controller: controller.usernameController,
                                  hintText: '10-digit mobile number',
                                  prefixIcon: IconlyLight.call,
                                  keyboardType: TextInputType.phone,
                                  // 10 digits only: an autofilled +91 / 0 is dropped, not cut into a wrong number.
                                  inputFormatters: const [MobileNumberFormatter()],
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                  ],
                                  validator: (value) {
                                    final mobile = value?.trim() ?? '';
                                    if (mobile.isEmpty) {
                                      return 'Enter your mobile number';
                                    }
                                    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
                                      return 'Enter a valid 10-digit mobile number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Password field label with orange lock icon
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 16,
                                      color: Color(0xFFF57C00),
                                    ),
                                    const SizedBox(width: 7),
                                    _label('Password', textColor),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Obx(
                                  () {
                                    final isVisible =
                                        controller.isPasswordVisible.value;
                                    return GlassTextField(
                                      controller: controller.passwordController,
                                      hintText: 'Enter your password',
                                      prefixIcon: IconlyLight.lock,
                                      obscureText: !isVisible,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) =>
                                          controller.login(),
                                      suffixIcon: IconButton(
                                        key: const Key(
                                          'login_password_visibility_toggle',
                                        ),
                                        focusNode: FocusNode(
                                          skipTraversal: true,
                                        ),
                                        onPressed: controller
                                            .togglePasswordVisibility,
                                        icon: Icon(
                                          isVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: isDark
                                              ? AppTheme.primaryGold
                                              : AppTheme.secondaryOrange,
                                          size: 19,
                                        ),
                                      ),
                                      validator: (value) =>
                                          (value?.isEmpty ?? true)
                                              ? 'Enter your password'
                                              : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.forgot_password),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Color(0xFFE65100),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Obx(
                                  () => GlassButton(
                                    isLoading: controller.isLoading.value,
                                    onPressed: controller.login,
                                    borderRadius: 14,
                                    gradientColors: const [
                                      Color(0xFFE65100),
                                      Color(0xFFF57C00),
                                      Color(0xFFFFA000),
                                    ],
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign in securely',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New to DaalSetu? ',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.register),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Create account',
                                  style: TextStyle(
                                    color: Color(0xFFE65100),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Decorative security separator line with centered shield badge
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(3.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF1E2538)
                                        : const Color(0xFFFFF3E0),
                                    border: Border.all(
                                      color: const Color(0xFFF57C00)
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    size: 12,
                                    color: Color(0xFFE65100),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Protected secure access
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: Color(0xFFE65100),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Protected secure access',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandHeader(Color textColor, Color subtextColor, bool isDark) {
    return Column(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              // Outer diffused ambient halo
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(
                  alpha: isDark ? 0.32 : 0.25,
                ),
                blurRadius: 36,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha: 0.18),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFFFFB300) : Colors.white,
              width: 2.2,
            ),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/app_icon.jpeg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DaalSetu',
          style: TextStyle(
            color: textColor,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),

        // Tagline flanked by horizontal decorative accent lines
        Stack(
          alignment: Alignment.center,
          children: [
            // Decorative line spanning behind the badge
            Container(
              height: 1.2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFE65100).withValues(alpha: 0.40),
                    const Color(0xFFE65100).withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Tagline badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF261D1A) : const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE65100).withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: const Text(
                'Smarter Trading. Stronger Connections.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFBF360C),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pulse Trading Platform',
          style: TextStyle(
            color: subtextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
  );
}
