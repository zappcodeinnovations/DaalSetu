import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../utils/input_validators.dart';
import '../controller/register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController _controller = RegisterController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _Glow(
                size: 280,
                color: AppTheme.primaryGold,
                isDark: isDark,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: _Glow(
                size: 260,
                color: AppTheme.secondaryOrange,
                isDark: isDark,
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: viewport.maxWidth >= 820
                          ? _desktopLayout(context)
                          : _mobileLayout(context),
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

  Widget _desktopLayout(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.borderColor
        : AppTheme.primaryGold.withValues(alpha: .55);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 360, child: _BrandPanel()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(42, 38, 42, 34),
                child: _registrationForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back to sign in',
              onPressed: () => Get.offNamed(AppRoutes.login),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Spacer(),
          ],
        ),
        const _MobileBrandHeader(),
        const SizedBox(height: 22),
        GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          borderColor: AppTheme.primaryGold.withValues(alpha: .38),
          glowColor: AppTheme.primaryGold,
          child: _registrationForm(context),
        ),
      ],
    );
  }

  Widget _registrationForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subtextColor = isDark
        ? AppTheme.textSecondary
        : const Color(0xFF8A6429);

    return Form(
      key: _controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create Account',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 27,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join DaalSetu and connect with verified buyers, sellers and transporters.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtextColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 580;
              final width = twoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'First Name',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.firstNameController,
                        hintText: 'Enter first name',
                        prefixIcon: IconlyLight.profile,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        validator: (value) => _required(value, 'First name'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Last Name',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.lastNameController,
                        hintText: 'Enter last name',
                        prefixIcon: IconlyLight.profile,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        validator: (value) => _required(value, 'Last name'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Email',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.emailController,
                        hintText: 'Enter email address',
                        prefixIcon: IconlyLight.message,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (value) =>
                            InputValidators.email(value, required: true),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Mobile',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.mobileController,
                        hintText: 'Enter 10-digit mobile number',
                        prefixIcon: IconlyLight.call,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) =>
                            RegExp(r'^\d{10}$').hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Enter a valid 10-digit mobile number',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Company Name',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.companyNameController,
                        hintText: 'Enter company name',
                        prefixIcon: IconlyLight.work,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.organizationName],
                        validator: (value) => _required(value, 'Company name'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Role',
                      required: true,
                      child: _dropdown(
                        value: _controller.selectedRole,
                        icon: IconlyLight.profile,
                        hint: 'Select role',
                        items: RegisterController.roles,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _controller.selectedRole = value);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Branch Code',
                      child: GlassTextField(
                        controller: _controller.branchCodeController,
                        hintText: 'Enter branch code',
                        prefixIcon: IconlyLight.home,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Za-z0-9_-]'),
                          ),
                          LengthLimitingTextInputFormatter(20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Gender',
                      child: _dropdown(
                        value: _controller.selectedGender,
                        icon: Icons.wc_outlined,
                        hint: 'Select gender',
                        items: const {
                          'male': 'Male',
                          'female': 'Female',
                          'other': 'Other',
                        },
                        onChanged: (value) =>
                            setState(() => _controller.selectedGender = value),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Password',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.passwordController,
                        hintText: 'Minimum 8 characters',
                        prefixIcon: IconlyLight.lock,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        suffixIcon: _passwordToggle(
                          visible: _showPassword,
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _field(
                      label: 'Confirm Password',
                      required: true,
                      child: GlassTextField(
                        controller: _controller.confirmPasswordController,
                        hintText: 'Confirm password',
                        prefixIcon: IconlyLight.lock,
                        obscureText: !_showConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        suffixIcon: _passwordToggle(
                          visible: _showConfirmPassword,
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) =>
                            value == _controller.passwordController.text
                            ? null
                            : 'Passwords do not match',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: isDark ? .12 : .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: .42),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.primaryGold,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Set a strong password. You can use it to sign in immediately after registration.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassButton(
            isLoading: _controller.isLoading,
            onPressed: _submit,
            height: 54,
            borderRadius: 13,
            gradientColors: const [AppTheme.primaryGold, Color(0xFFFF5722)],
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create Account'),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Get.offNamed(AppRoutes.login),
              child: const Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(
                        color: AppTheme.secondaryOrange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    bool required = false,
    required Widget child,
  }) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.textSecondary
        : const Color(0xFF704D18);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ]
                : const [],
          ),
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _dropdown({
    required String? value,
    required IconData icon,
    required String hint,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: theme.cardColor,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppTheme.bgSecondary : const Color(0xFFF1F5F9),
        prefixIcon: Icon(icon, color: AppTheme.primaryGold, size: 20),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _passwordToggle({
    required bool visible,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: visible ? 'Hide password' : 'Show password',
      onPressed: onPressed,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    );
  }

  String? _required(String? value, String label) {
    return (value?.trim().isEmpty ?? true) ? '$label is required' : null;
  }

  Future<void> _submit() async {
    if (_controller.isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {});
    try {
      final registration = _controller.register();
      setState(() {});
      final message = await registration;
      if (message == null || !mounted) return;
      AppSnackbar.showSuccess(message: message);
      final mobile = _controller.mobileController.text.trim();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        Get.offAllNamed(
          AppRoutes.login,
          arguments: {'mobile': mobile, 'registered': true},
        );
      }
    } catch (error) {
      if (mounted) AppSnackbar.showError(message: error.toString());
    } finally {
      if (mounted) setState(() {});
    }
  }
}

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: .7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: .22),
                blurRadius: 24,
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
        const SizedBox(height: 10),
        Text(
          'DaalSetu',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgSecondary : const Color(0xFFFFFBF2),
        border: Border(
          right: BorderSide(color: AppTheme.primaryGold.withValues(alpha: .45)),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/app_icon.jpeg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'A trusted platform connecting buyers, sellers and transporters for a better trade experience.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 34),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TrustItem(
                icon: Icons.shield_outlined,
                label: 'Secure\nPlatform',
              ),
              _TrustItem(
                icon: Icons.person_outline_rounded,
                label: 'Verified\nUsers',
              ),
              _TrustItem(
                icon: Icons.handshake_outlined,
                label: 'Trusted\nMarketplace',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.secondaryOrange),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, height: 1.3),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.isDark});
  final double size;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: isDark ? .12 : .10),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
