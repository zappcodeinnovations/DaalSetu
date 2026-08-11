import 'package:daalsetu/modules/Auth/forgot_password/model/forgot_password_model.dart';
import 'package:daalsetu/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {

  final emailController = TextEditingController();
  final isLoading = false.obs;

  /// ============================================================
  /// FORGOT PASSWORD FUNCTION
  /// ============================================================
  Future<void> submitForgotPassword() async {

    final email = emailController.text.trim();

    // ✅ Validation
    if (email.isEmpty) {
      Get.snackbar("Error", "Email is required");
      return;
    }

    if (!GetUtils.isEmail(email)) {
      Get.snackbar("Error", "Enter valid email");
      return;
    }

    try {
      isLoading.value = true;

      /// 🔥 Create Request Model
      final request = ForgotPasswordRequestModel(
        email: email,
      );

      /// 🔥 Call Service
      final ForgotPasswordResponseModel response =
          await AuthService.forgotPassword(
        request: request,
      );

      /// ✅ Success Message
      Get.snackbar("Success", response.message);

      emailController.clear();

    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
