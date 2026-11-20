import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/add_user_controller.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import '../controller/user_controller.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/utils/input_validators.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => AddUserScreenState();
}

class AddUserScreenState extends State<AddUserScreen> {
  late final AddUserController controller;

  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final branchController = TextEditingController();
  final panController = TextEditingController();
  final gstController = TextEditingController();

  // Same options and order as the web Create New User form.
  final roles = const ["admin", "sub_admin", "buyer", "seller", "transporter", "both_sellerandbuyer"];
  final genders = const ["male", "female", "other"];

  final selectedRole = "buyer".obs;
  final selectedGender = "".obs;
  final obscurePassword = true.obs;

  final panImage = Rx<File?>(null);
  final gstImage = Rx<File?>(null);

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AddUserController>()
        ? Get.find<AddUserController>()
        : Get.put(AddUserController());
    resetForm();
  }

  @override
  void dispose() {
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    branchController.dispose();
    panController.dispose();
    gstController.dispose();
    super.dispose();
  }

  /// Wipes all form fields clean so fresh empty placeholders are ready for the next entry.
  void resetForm() {
    mobileController.clear();
    emailController.clear();
    passwordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    branchController.clear();
    panController.clear();
    gstController.clear();

    selectedRole.value = "buyer";
    selectedGender.value = "";
    obscurePassword.value = true;

    panImage.value = null;
    gstImage.value = null;

    controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: "Add User",
        subtitle: "Register platform member & assign permissions",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            /// 🔥 HEADER CARD
            _headerCard(context),

            const SizedBox(height: 24),

            /// 🔥 FORM CARD
            _formCard(context),

            const SizedBox(height: 24),

            /// 🔥 SUBMIT BUTTON
            Obx(() => controller.isLoading.value
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE65100),
                          Color(0xFFF57C00),
                          Color(0xFFFFA000),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE65100).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final mobile = mobileController.text.trim();
                        final password = passwordController.text.trim();
                        final firstName = firstNameController.text.trim();
                        final email = emailController.text.trim();

                        if (firstName.isEmpty) {
                          AppSnackbar.snackbar(
                            "Required",
                            "Please enter first name",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        final nameError = InputValidators.personName(
                              firstName,
                              label: 'First name',
                            ) ??
                            InputValidators.personName(
                              lastNameController.text,
                              label: 'Last name',
                            );
                        if (nameError != null) {
                          AppSnackbar.snackbar(
                            "Invalid Name",
                            nameError,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        if (mobile.isEmpty) {
                          AppSnackbar.snackbar(
                            "Required",
                            "Please enter mobile number",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        if (mobile.length != 10 ||
                            !RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
                          AppSnackbar.snackbar(
                            "Invalid Mobile",
                            "Please enter a valid 10-digit numeric mobile number",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        if (password.isEmpty) {
                          AppSnackbar.snackbar(
                            "Required",
                            "Please enter password",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        if (password.length < 4) {
                          AppSnackbar.snackbar(
                            "Weak Password",
                            "Password must be at least 4 characters long",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        controller.createUser(
                          mobile: mobile,
                          email: email,
                          password: password,
                          firstName: firstName,
                          lastName: lastNameController.text.trim(),
                          role: selectedRole.value,
                          branchCode: branchController.text.trim(),
                          panNumber: panController.text.trim(),
                          gstNumber: gstController.text.trim(),
                          gender: selectedGender.value,
                          panImage: panImage.value,
                          gstImage: gstImage.value,
                          onSuccess: resetForm,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Create User",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// HEADER CARD
  /// ===============================
  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              IconlyLight.add_user,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Platform User",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Enter contact, credentials & identity details",
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFF57C00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// FORM CARD
  /// ===============================
  Widget _formCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Personal Information ──
          _sectionHeader("Personal Information"),
          _textField("First Name *", firstNameController),
          _textField("Last Name (Optional)", lastNameController),
          _textField(
            "Mobile (10 Digits) *",
            mobileController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          _textField(
            "Email",
            emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          _dropdown("Role *", roles, selectedRole),
          const SizedBox(height: 16),
          _textField("Branch Code (Optional)", branchController),
          _tagDropdown(context),
          const SizedBox(height: 16),
          _dropdown("Gender (Optional)", genders, selectedGender),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── 2. Authentication ──
          _sectionHeader("Authentication"),
          Obx(
            () => _textField(
              "Password *",
              passwordController,
              obscureText: obscurePassword.value,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    obscurePassword.value = !obscurePassword.value,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── 3. Business Information ──
          _sectionHeader("Business Information"),
          _textField("PAN Number (Optional)", panController),
          _textField("GST Number (Optional)", gstController),

          const SizedBox(height: 20),
          _imagePicker(context, "PAN Image", panImage),
          const SizedBox(height: 16),
          _imagePicker(context, "GST Image", gstImage),
        ],
      ),
    );
  }

  Widget _tagDropdown(BuildContext context) {
    return Obx(
      () => DropdownButtonFormField<int>(
        initialValue: controller.selectedTagId.value,
        items: controller.tags.map((tag) {
          return DropdownMenuItem<int>(
            value: tag.id,
            child: Text(tag.tagName),
          );
        }).toList(),
        onChanged: (value) {
          controller.selectedTagId.value = value;
        },
        decoration: InputDecoration(
          labelText: "Select Tag",
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, RxString selected) {
    return Obx(
      () => DropdownButtonFormField<String>(
        initialValue: selected.value.isEmpty ? null : selected.value,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(items == roles ? UserController.roleLabel(e) : e.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (val) => selected.value = val ?? "",
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _imagePicker(BuildContext context, String label, Rx<File?> image) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
            if (picked != null) {
              image.value = File(picked.path);
            }
          },
          child: Obx(() => Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: image.value == null
                    ? Center(
                        child: Text(
                          "Tap to select image",
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(image.value!, fit: BoxFit.cover),
                      ),
              )),
        ),
      ],
    );
  }
}
