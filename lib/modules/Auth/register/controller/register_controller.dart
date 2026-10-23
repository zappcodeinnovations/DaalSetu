import 'package:flutter/material.dart';

import '../../../../services/auth_services.dart';

class RegisterController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final branchCodeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  /// Public self-registration roles match the web registration form.
  static const Map<String, String> roles = {
    'buyer': 'Buyer',
    'seller': 'Seller',
    'transporter': 'Transporter',
  };

  String selectedRole = 'buyer';
  String? selectedGender;
  bool isLoading = false;

  Map<String, String> buildFields() => {
    'mobile': mobileController.text.trim(),
    'email': emailController.text.trim(),
    'first_name': firstNameController.text.trim(),
    'last_name': lastNameController.text.trim(),
    'company_name': companyNameController.text.trim(),
    'role': selectedRole,
    'branch_code': branchCodeController.text.trim().toUpperCase(),
    'gender': selectedGender ?? '',
    'password': passwordController.text,
    'confirm_password': confirmPasswordController.text,
  };

  Future<String?> register() async {
    if (isLoading || !(formKey.currentState?.validate() ?? false)) return null;

    isLoading = true;
    try {
      return await AuthService.register(fields: buildFields());
    } finally {
      isLoading = false;
    }
  }

  void dispose() {
    mobileController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    companyNameController.dispose();
    branchCodeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
