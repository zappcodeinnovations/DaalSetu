import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/add_user_controller.dart';

class AddUserScreen extends StatelessWidget {
  AddUserScreen({super.key});

  final controller = Get.put(AddUserController());

  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final panController = TextEditingController();
  final gstController = TextEditingController();

  final roles = ["buyer", "seller", "transporter", "admin"];
  final genders = ["male", "female", "other"];

  final selectedRole = "buyer".obs;
  final selectedGender = "".obs;

  final panImage = Rx<File?>(null);
  final gstImage = Rx<File?>(null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
                        controller.createUser(
                          mobile: mobileController.text,
                          email: emailController.text,
                          firstName: firstNameController.text,
                          lastName: lastNameController.text,
                          role: selectedRole.value,
                          panNumber: panController.text,
                          gstNumber: gstController.text,
                          gender: selectedGender.value,
                          panImage: panImage.value,
                          gstImage: gstImage.value,
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
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
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
        children: [
          _textField("Mobile", mobileController),
          _textField("Email", emailController),
          _textField("First Name", firstNameController),
          _textField("Last Name (Optional)", lastNameController),

          const SizedBox(height: 16),

          _dropdown("Role", roles, selectedRole),
          const SizedBox(height: 16),
          _tagDropdown(context),

          const SizedBox(height: 16),

          _textField("PAN Number (Optional)", panController),
          _textField("GST Number (Optional)", gstController),

          const SizedBox(height: 16),

          _dropdown("Gender (Optional)", genders, selectedGender),

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
        value: controller.selectedTagId.value,
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

  Widget _textField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }


  Widget _dropdown(String label, List<String> items, RxString selected) {
    return Obx(
      () => DropdownButtonFormField<String>(
        value: selected.value.isEmpty ? null : selected.value,
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
