import '../../../../services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;

  /// ============================================================
  /// CHANGE PASSWORD
  /// ============================================================
  Future<void> changePassword() async {

    if (oldPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {

      Get.snackbar("Error", "All fields are required");
      return;
    }

    if (newPasswordController.text !=
        confirmPasswordController.text) {

      Get.snackbar("Error", "New password and confirm password do not match");
      return;
    }

    try {
      isLoading.value = true;

      final message = await AuthService.changePassword(
        oldPassword: oldPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      Get.snackbar("Success", message);

      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

    } catch (e) {
      Get.snackbar("Error", e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
