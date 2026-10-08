import '../../../../services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:daalsetu/utils/tax_id_formatters.dart';

class RegisterController {
  /// FORM KEY
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// TEXT CONTROLLERS
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Self sign-up roles (admins are created by admins, never from this screen).
  static const Map<String, String> roles = {
    'buyer': 'Buyer',
    'seller': 'Seller',
    'transporter': 'Transporter',
    'both_sellerandbuyer': 'Seller + Buyer',
  };
  String? selectedRole;

  /// ============================
  /// OTHER FIELDS
  /// ============================
  String? selectedGender;

  String? panImagePath;
  String? gstImagePath;

  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();

  /// ============================
  /// PICK IMAGE
  /// ============================
  Future<void> pickImage(bool isPan) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (isPan) {
        panImagePath = pickedFile.path;
      } else {
        gstImagePath = pickedFile.path;
      }
    }
  }

  /// ============================
  /// REGISTER USER
  /// ============================
  Future<String?> register() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }

    final gstPanError = TaxIdValidator.gstMatchesPan(
      panController.text,
      gstController.text,
    );
    if (gstPanError != null) throw Exception(gstPanError);

    if (selectedRole == null) {
      throw Exception("Please select user type");
    }

    if (passwordController.text.length < 8) {
      throw Exception("Password must be at least 8 characters");
    }

    if (passwordController.text != confirmPasswordController.text) {
      throw Exception("Passwords do not match");
    }

    if (selectedGender == null) {
      throw Exception("Please select gender");
    }

    if (panImagePath == null) {
      throw Exception("Please upload PAN image");
    }

    if (gstImagePath == null) {
      throw Exception("Please upload GST image");
    }

    try {
      isLoading = true;

      final message = await AuthService.register(
        fields: {
          "mobile": mobileController.text.trim(),
          "email": emailController.text.trim(),
          "first_name": firstNameController.text.trim(),
          "last_name": lastNameController.text.trim(),
          "role": selectedRole!,
          "password": passwordController.text,
          "confirm_password": confirmPasswordController.text,
          "pan_number": panController.text.trim().toUpperCase(),
          "gst_number": gstController.text.trim().toUpperCase(),
          "gender": selectedGender!,
          "dob": dobController.text.trim(),
        },
        files: {"pan_image": panImagePath!, "gst_image": gstImagePath!},
      );

      return message;
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
    }
  }

  /// ============================
  /// DISPOSE CONTROLLERS
  /// ============================
  void dispose() {
    mobileController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    panController.dispose();
    gstController.dispose();
    dobController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
