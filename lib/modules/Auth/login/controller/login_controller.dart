import 'package:iconly/iconly.dart';
import 'package:daalsetu/modules/Auth/login/model/login_model.dart';
import 'package:daalsetu/services/auth_services.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/routes/app_routes.dart';

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

      if (response.user.accountStatus != "active") {
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

      final allowedRoles = ["admin", "seller", "transporter", "buyer"];
      if (!allowedRoles.contains(response.user.role)) {
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

                  /// TITLE
                  const Text(
                    "Access Denied",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// MESSAGE
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

                  /// BUTTON
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
      );

      Get.offAllNamed(AppRoutes.mainNav);
    } catch (e) {
      Get.defaultDialog(
        title: "Login Failed",
        middleText: e.toString(),
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
