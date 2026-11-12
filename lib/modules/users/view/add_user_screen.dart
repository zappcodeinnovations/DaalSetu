import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/add_user_controller.dart';
import 'package:daalsetu/widgets/app_shell.dart';
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

  final roles = const ["buyer", "seller", "transporter", "admin", "salesman"];
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
      appBar: AppBar(
        leading: const AppBarLeading(),
        leadingWidth: AppBarLeading.widthFor(context),
        elevation: 0,
        title: const Text("Add User"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 🔥 HEADER CARD
            _headerCard(context),

            const SizedBox(height: 24),

            /// 🔥 FORM CARD
            _formCard(context),

            const SizedBox(height: 30),

            /// 🔥 SUBMIT BUTTON
            Obx(() => controller.isLoading.value
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Create User",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            IconlyLight.add_user,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            "Create New User",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Fill the details below to register a new user",
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
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
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF58220),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// FORM CARD
  /// ===============================
  Widget _formCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
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
              (e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())),
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
