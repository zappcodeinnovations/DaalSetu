import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../model/login_model.dart';
import '../../../../services/auth_services.dart';
import '../../../../utils/app_preferences.dart';
import '../../../../routes/app_routes.dart';

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

      final accountStatus = response.user.accountStatus.trim().toLowerCase();
      final status = response.user.status.trim().toLowerCase();
      final role = response.user.role.trim().toLowerCase();

      if (accountStatus != "active" || status != "active") {
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

      final allowedRoles = ["admin", "seller", "transporter", "buyer", "both_sellerandbuyer", "sub_admin"];
      if (!allowedRoles.contains(role)) {
        await AppPreferences.logout();

        Get.dialog(
          Dialog(
            backgroundColor: const Color(0xFF151A27),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1661EF).withOpacity(0.15),
                    ),
                    child: const Icon(
                      IconlyLight.shield_done,
                      size: 40,
                      color: Color(0xFF1661EF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Access Denied",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Your role does not have access to this portal.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A94A6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1661EF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
