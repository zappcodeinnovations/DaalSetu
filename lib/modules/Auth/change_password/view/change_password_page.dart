import 'package:agro_broker/modules/Auth/login/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/change_password_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  ChangePasswordScreen({super.key});

  final controller = Get.put(ChangePasswordController());

  // Local state for password visibility toggles (UI logic)
  // In a strict MVVM architecture, these could be inside your controller, 
  // but for UI purposes, local RxBools work fine here.
  final RxBool _isOldPassHidden = true.obs;
  final RxBool _isNewPassHidden = true.obs;
  final RxBool _isConfirmPassHidden = true.obs;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0F172A); 
    const inputFillColor = Color(0xFF1E293B);  
    const primaryGreen = Color(0xFF2E7D32);
    const hintColor = Colors.grey;
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Description
              const Text(
                "Please enter your current password and your new desired password to update your account security.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // OLD PASSWORD
              _buildPasswordField(
                label: "Old Password",
                hint: "Enter old password",
                controller: controller.oldPasswordController,
                obscureText: _isOldPassHidden,
                fillColor: inputFillColor,
                textColor: textColor,
                hintColor: hintColor,
              ),

              const SizedBox(height: 20),

              // NEW PASSWORD
              _buildPasswordField(
                label: "New Password",
                hint: "Enter new password",
                controller: controller.newPasswordController,
                obscureText: _isNewPassHidden,
                fillColor: inputFillColor,
                textColor: textColor,
                hintColor: hintColor,
              ),

              const SizedBox(height: 20),

              // CONFIRM PASSWORD
              _buildPasswordField(
                label: "Confirm Password",
                hint: "Confirm new password",
                controller: controller.confirmPasswordController,
                obscureText: _isConfirmPassHidden,
                fillColor: inputFillColor,
                textColor: textColor,
                hintColor: hintColor,
              ),

              const SizedBox(height: 25),

              // Tip Text
              const Text(
                "Tip: A strong password should be at least 8 characters long and include a mix of letters, numbers, and symbols.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 40),

              // BUTTON
              Obx(() => SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Widget for the styled text fields
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required RxBool obscureText,
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextField(
          controller: controller,
          obscureText: obscureText.value,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            hintText: hint,
            hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: hintColor),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: hintColor,
              ),
              onPressed: () => obscureText.value = !obscureText.value,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        )),
      ],
    );
  }
}