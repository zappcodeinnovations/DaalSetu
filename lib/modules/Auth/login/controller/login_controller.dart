import 'package:agro_broker/modules/Auth/login/model/login_model.dart';
import 'package:agro_broker/services/auth_services.dart';
import 'package:agro_broker/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agro_broker/routes/app_routes.dart';

class LoginController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var isLoading = false.obs;

  Future<void> login() async {
    final form = formKey.currentState;

    if (form == null || !form.validate()) return;

    try {
      isLoading.value = true;

      final LoginResponse response = await AuthService.login(
        mobile: usernameController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user.accountStatus.toLowerCase() != "active" ||
          response.user.status.toLowerCase() != "active") {
        await AppPreferences.logout();

        Get.defaultDialog(
          title: "Account Inactive",
          middleText: "Your account is not active.",
          textConfirm: "OK",
          confirmTextColor: Colors.white,
          onConfirm: () => Get.back(),
        );

        return;
      }

      if (response.user.role.toLowerCase() != "admin") {
        await AppPreferences.logout();

        _showMessage(
          title: "Admin access only",
          message: "This portal is restricted to administrator accounts.",
        );

        return;
      }

      // Save tokens
      await AppPreferences.saveLoginData(
        accessToken: response.access,
        refreshToken: response.refresh,
        role: response.user.role,
        userId: response.user.id.toString(),
        username: response.user.username,
        activeBranchId: response.user.activeBranchId?.toString(),
        activeBranchCode: response.user.activeBranchCode,
      );

      Get.offAllNamed(AppRoutes.mainNav);
    } catch (e) {
      _showMessage(title: "Unable to sign in", message: _friendlyError(e));
    } finally {
      isLoading.value = false;
    }
  }

  void _showMessage({required String title, required String message}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF1F2937),
      colorText: Colors.white,
      icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
    );
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains("unauthorized") || text.contains("401")) {
      return "The mobile number or password is incorrect.";
    }
    if (text.contains("socket") || text.contains("internet")) {
      return "Check your internet connection and try again.";
    }
    if (text.contains("timeout")) {
      return "The server took too long to respond. Please try again.";
    }
    if (text.contains("server error") || text.contains("500")) {
      return "The server is temporarily unavailable. Please try again later.";
    }
    return "Sign-in failed. Please verify your details and try again.";
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
