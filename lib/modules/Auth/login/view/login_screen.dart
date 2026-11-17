import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/login_controller.dart';

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
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subtextColor = isDark
        ? AppTheme.textSecondary
        : AppTheme.textSecondaryLight;
    final mutedColor = isDark ? AppTheme.textMuted : AppTheme.textMutedLight;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 280,
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
            Positioned(
              top: -110,
              right: -90,
              child: _Glow(
                size: 280,
                color: const Color(0xFFFFB300),
                isDark: isDark,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: _Glow(
                size: 250,
                color: const Color(0xFFFF6D00),
                isDark: isDark,
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        children: [
                          _brandHeader(textColor, subtextColor, isDark),
                          const SizedBox(height: 28),
                          GlassCard(
                            borderRadius: 24,
                            blur: 24,
                            padding: const EdgeInsets.all(24),
                            borderColor: isDark
                                ? const Color(0xFFFFB300).withValues(alpha: 0.28)
                                : const Color(0xFFFFB74D).withValues(alpha: 0.45),
                            glowColor: isDark ? AppTheme.primaryGold : const Color(0xFFFFE082),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 13,
                                            color: Color(0xFF059669),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Encrypted',
                                            style: TextStyle(
                                              color: Color(0xFF059669),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Use your registered mobile number to continue.',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                _label('Mobile number', textColor),
                                const SizedBox(height: 8),
                                GlassTextField(
                                  controller: controller.usernameController,
                                  hintText: '10-digit mobile number',
                                  prefixIcon: IconlyLight.call,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
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
                                const SizedBox(height: 18),
                                _label('Password', textColor),
                                const SizedBox(height: 8),
                                Obx(
                                  () {
                                    final isVisible = controller.isPasswordVisible.value;
                                    return GlassTextField(
                                      controller: controller.passwordController,
                                      hintText: 'Enter your password',
                                      prefixIcon: IconlyLight.lock,
                                      obscureText: !isVisible,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [AutofillHints.password],
                                      onFieldSubmitted: (_) => controller.login(),
                                      suffixIcon: IconButton(
                                        key: const Key('login_password_visibility_toggle'),
                                        focusNode: FocusNode(skipTraversal: true),
                                        onPressed: controller.togglePasswordVisibility,
                                        icon: Icon(
                                          isVisible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: isDark
                                              ? AppTheme.primaryGold
                                              : AppTheme.secondaryOrange,
                                          size: 20,
                                        ),
                                      ),
                                      validator: (value) => (value?.isEmpty ?? true)
                                          ? 'Enter your password'
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
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
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Obx(
                                  () => GlassButton(
                                    isLoading: controller.isLoading.value,
                                    onPressed: controller.login,
                                    borderRadius: 16,
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
                                            fontSize: 16,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward_rounded,
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
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New to DaalSetu? ',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 14,
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 15,
                                color: isDark
                                    ? AppTheme.primaryGold
                                    : AppTheme.secondaryOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Protected secure access',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha: 0.30),
                blurRadius: 30,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFFFFB300) : Colors.white,
              width: 2.5,
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
        const SizedBox(height: 16),
        Text(
          'DaalSetu',
          style: TextStyle(
            color: textColor,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE65100).withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: const Text(
                'KISOR',
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pulse Trading Platform',
              style: TextStyle(
                color: subtextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text, Color color) => Text(
    text,
    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, this.isDark = true});

  final double size;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.18 : 0.08),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
