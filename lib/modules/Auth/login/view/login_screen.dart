import 'package:agro_broker/routes/app_routes.dart';
import 'package:agro_broker/theme/glass_widgets.dart';
import 'package:agro_broker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../controller/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LoginController>();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textPrimary;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgDarkNavy,
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -110,
              right: -90,
              child: _Glow(size: 280, color: Color(0xFFFFB300)),
            ),
            const Positioned(
              bottom: -100,
              left: -100,
              child: _Glow(size: 250, color: Color(0xFFFF6D00)),
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
                          _brandHeader(textColor),
                          const SizedBox(height: 28),
                          GlassCard(
                            borderRadius: 28,
                            blur: 24,
                            padding: const EdgeInsets.all(24),
                            glowColor: AppTheme.primaryGold,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Administrator sign in',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Use your registered mobile number to continue.',
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.62),
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                                    if (!RegExp(
                                      r'^\d{10}$',
                                    ).hasMatch(mobile)) {
                                      return 'Enter a valid 10-digit mobile number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _label('Password', textColor),
                                    TextButton(
                                      onPressed: () => Get.toNamed(
                                        AppRoutes.forgot_password,
                                      ),
                                      child: const Text('Forgot password?'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                GlassTextField(
                                  controller: controller.passwordController,
                                  hintText: 'Enter your password',
                                  prefixIcon: IconlyLight.lock,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => controller.login(),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword
                                        ? 'Hide password'
                                        : 'Show password',
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  validator: (value) => (value?.isEmpty ?? true)
                                      ? 'Enter your password'
                                      : null,
                                ),
                                const SizedBox(height: 26),
                                Obx(
                                  () => GlassButton(
                                    isLoading: controller.isLoading.value,
                                    onPressed: controller.login,
                                    borderRadius: 16,
                                    gradientColors: const [
                                      AppTheme.primaryGold,
                                      AppTheme.secondaryOrange,
                                    ],
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sign in securely',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 15,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Protected administrator access',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.55),
                                  fontSize: 12,
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

  Widget _brandHeader(Color textColor) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.28),
                blurRadius: 28,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_icon.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'DaalSetu Admin',
          style: TextStyle(
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Operations control centre',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
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
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
