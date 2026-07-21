import 'package:agro_broker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

// Color Palette based on the image
class AppColors {
  static const Color background = Color(0xFF0F131F); // Dark Navy
  static const Color cardSurface = Color(0xFF151A27); // Input background
  static const Color primaryBlue = Color(0xFF1661EF); // Bright Blue
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFF8A94A6);
  static const Color border = Color(0xFF242A38);
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  // Local state for UI toggles (Password visibility & Checkbox)
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _rememberMe = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          "Admin Portal",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                /// LOGO SECTION
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF132238),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E2E48)),
                  ),
                  child: const Icon(
                    Icons.security, // Shield icon similar to image
                    size: 40,
                    color: AppColors.primaryBlue,
                  ),
                ),

                const SizedBox(height: 24),

                /// WELCOME TEXT
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Secure access for Dal platform management",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),

                const SizedBox(height: 40),

                /// USERNAME / ADMIN ID
                _buildLabel("Admin ID or Email"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    hint: "Enter your admin ID",
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter Admin ID" : null,
                ),

                const SizedBox(height: 20),

                /// PASSWORD LABEL & FORGOT LINK
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel("Password"),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.forgot_password);
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                /// PASSWORD INPUT
                ValueListenableBuilder<bool>(
                  valueListenable: _isPasswordVisible,
                  builder: (context, isVisible, child) {
                    return TextFormField(
                      controller: controller.passwordController,
                      obscureText: !isVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _inputDecoration(
                            hint: "••••••••",
                            prefixIcon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                isVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textGrey,
                              ),
                              onPressed: () {
                                _isPasswordVisible.value = !isVisible;
                              },
                            ),
                          ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter password" : null,
                    );
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _rememberMe,
                          builder: (context, val, child) {
                            return SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: val,
                                activeColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                  color: AppColors.textGrey,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (value) =>
                                    _rememberMe.value = value!,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Remember this device",
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // const Row(
                    //   children: [
                    //     Icon(Icons.fingerprint,
                    //         color: Color(0xFF2C3545), size: 18),
                    //     SizedBox(width: 6),
                    //     Text(
                    //       "Biometrics enabled",
                    //       style: TextStyle(
                    //         color: Color(0xFF4A5568),
                    //         fontSize: 12,
                    //       ),
                    //     ),
                    //   ],
                    // )
                  ],
                ),

                const SizedBox(height: 30),

                /// LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                      ),
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.login,
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Sign In to Dashboard",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                /// ASSISTANCE CARD
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF161B26),
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: AppColors.border),
                //   ),
                //   child: Row(
                //     children: [
                //       Container(
                //         padding: const EdgeInsets.all(8),
                //         decoration: BoxDecoration(
                //           color: const Color(0xFF1E2738),
                //           shape: BoxShape.circle,
                //         ),
                //         child: const Icon(Icons.headset_mic_outlined,
                //             color: AppColors.primaryBlue, size: 20),
                //       ),
                //       const SizedBox(width: 15),
                //       const Expanded(
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: [
                //             Text(
                //               "Need assistance?",
                //               style: TextStyle(
                //                 color: Colors.white,
                //                 fontWeight: FontWeight.bold,
                //                 fontSize: 14,
                //               ),
                //             ),
                //             SizedBox(height: 4),
                //             Text(
                //               "Contact the technical team for access credentials.",
                //               style: TextStyle(
                //                 color: AppColors.textGrey,
                //                 fontSize: 12,
                //               ),
                //             ),
                //           ],
                //         ),
                //       )
                //     ],
                //   ),
                // ),

                // const SizedBox(height: 30),

                // /// FOOTER SECURITY NOTE
                // const Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Icon(Icons.verified_user_outlined,
                //         color: Color(0xFF4A5568), size: 14),
                //     SizedBox(width: 6),
                //     Text(
                //       "End-to-end Encrypted Administration Session",
                //       style: TextStyle(
                //         color: Color(0xFF4A5568),
                //         fontSize: 11,
                //       ),
                //     ),
                //   ],
                // ),

                // Keep the register link but style it minimally or hide if not needed for Admin
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Get.toNamed('/register'),
                  child: const Text(
                    "Register New Account",
                    style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper for input labels
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Helper for Input Decoration
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.cardSurface,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade500, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
