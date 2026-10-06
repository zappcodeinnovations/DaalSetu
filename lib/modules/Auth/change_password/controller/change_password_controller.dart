import '../../../../services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final newPasswordText = "".obs;

  @override
  void onInit() {
    super.onInit();
    newPasswordController.addListener(() {
      newPasswordText.value = newPasswordController.text;
    });
  }

  // Password validation rules
  bool get hasMinLength => newPasswordText.value.length >= 8;
  bool get hasLetter => RegExp(r'[a-zA-Z]').hasMatch(newPasswordText.value);
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(newPasswordText.value);
  bool get hasSymbol => RegExp(r'[^a-zA-Z0-9]').hasMatch(newPasswordText.value);
  bool get isNewPasswordValid =>
      hasMinLength && hasLetter && hasNumber && hasSymbol;

  /// ============================================================
  /// CHANGE PASSWORD
  /// ============================================================
  Future<void> changePassword() async {
    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      Get.snackbar(
        "Error",
        "All fields are required",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (newPassword.length < 8) {
      Get.snackbar(
        "Error",
        "Password must be at least 8 characters long",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final hasLetterMatch = RegExp(r'[a-zA-Z]').hasMatch(newPassword);
    final hasNumberMatch = RegExp(r'[0-9]').hasMatch(newPassword);
    final hasSymbolMatch = RegExp(r'[^a-zA-Z0-9]').hasMatch(newPassword);

    if (!hasLetterMatch || !hasNumberMatch || !hasSymbolMatch) {
      Get.snackbar(
        "Error",
        "Password must contain letters, numbers, and symbols",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (newPassword == oldPassword) {
      Get.snackbar(
        "Error",
        "New password cannot be the same as old password",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      Get.snackbar(
        "Error",
        "New password and confirm password do not match",
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      isLoading.value = true;

      final message = await AuthService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      Get.snackbar(
        "Success",
        message,
        snackPosition: SnackPosition.TOP,
      );

      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", ""),
        snackPosition: SnackPosition.TOP,
      );
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

