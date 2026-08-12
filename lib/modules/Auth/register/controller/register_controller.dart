import '../../../../services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  /// STATIC ROLE
  static const String role = "admin"; // 🔥 fixed role

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
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (isPan) {
        panImagePath = pickedFile.path;
      } else {
        gstImagePath = pickedFile.path;
      }
    }
  }

  /// ============================
  /// REGISTER USER (ADMIN ONLY)
  /// ============================
  Future<String?> register() async {

    if (!formKey.currentState!.validate()) {
      return null;
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
          "role": role, // 🔥 always admin
          "pan_number": panController.text.trim(),
          "gst_number": gstController.text.trim(),
          "gender": selectedGender!,
          "dob": dobController.text.trim(),
        },
        files: {
          "pan_image": panImagePath!,
          "gst_image": gstImagePath!,
        },
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
  }
}
