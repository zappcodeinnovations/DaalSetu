import 'package:iconly/iconly.dart';
import '../controller/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:daalsetu/theme/app_theme.dart';

class AppColors {
  static Color get background => Get.theme.scaffoldBackgroundColor;
  static Color get cardSurface => Get.theme.cardColor;
  static Color get primaryBrand => Get.theme.primaryColor;
  static Color get textWhite => Get.theme.textTheme.bodyLarge?.color ?? Colors.white;
  static Color get textGrey => Get.theme.textTheme.bodyMedium?.color ?? Colors.grey;
  static Color get border => Get.theme.dividerColor;
  static Color get successGreen => AppTheme.successGreen;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final RegisterController _controller = RegisterController();

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryBrand,
              onPrimary: Colors.white,
              surface: AppColors.cardSurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _controller.dobController.text =
            pickedDate.toIso8601String().split("T").first;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: Icon(IconlyLight.arrow_left, color: AppColors.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Register New User",
          style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("USER TYPE"),
              const SizedBox(height: 8),
              _buildRoleSelector(),

              const SizedBox(height: 25),
              _buildSectionHeader(IconlyLight.profile, "PERSONAL DETAILS"),
              const SizedBox(height: 20),

              // First Name & Last Name Row
              Row(
                children: [
                  Expanded(
                    child: _buildDarkTextField(
                      controller: _controller.firstNameController,
                      label: "First Name",
                      hint: "First Name",
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDarkTextField(
                      controller: _controller.lastNameController,
                      label: "Last Name",
                      hint: "Last Name",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildDarkTextField(
                controller: _controller.mobileController,
                label: "Mobile Number",
                hint: "Enter Your Mobile Number",
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              _buildDarkTextField(
                controller: _controller.emailController,
                label: "Email Address",
                hint: "Enter Your Email Address",
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _buildDarkTextField(
                      controller: _controller.passwordController,
                      label: "Password",
                      hint: "Min 8 characters",
                      obscure: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDarkTextField(
                      controller: _controller.confirmPasswordController,
                      label: "Confirm Password",
                      hint: "Re-enter password",
                      obscure: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Gender & DOB Row
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: "Gender",
                      value: _controller.selectedGender,
                      items: ["male", "female", "other"],
                      onChanged: (val) => setState(() => _controller.selectedGender = val),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildReadOnlyField(
                      controller: _controller.dobController,
                      label: "Date of Birth",
                      hint: "Select Date",
                      icon: IconlyLight.calendar,
                      onTap: _selectDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              _buildSectionHeader(IconlyLight.work, "BUSINESS DETAILS"),
              const SizedBox(height: 20),

              _buildDarkTextField(
                controller: _controller.panController,
                label: "PAN Number",
                hint: "ABCDE1234E",
              ),
              const SizedBox(height: 15),

              _buildDarkTextField(
                controller: _controller.gstController,
                label: "GST Number",
                hint: "22AAAAA0000A1Z5",
              ),

              const SizedBox(height: 30),
              _buildSectionHeader(IconlyLight.document, "VERIFICATION DOCUMENTS"),
              const SizedBox(height: 20),

              _buildDocumentCard(
                title: "PAN Image",
                icon: IconlyLight.wallet,
                hasImage: _controller.panImagePath != null,
                onTap: () async {
                  await _controller.pickImage(true);
                  setState(() {});
                },
              ),
              const SizedBox(height: 15),
              _buildDocumentCard(
                title: "GST Image",
                icon: IconlyLight.document,
                hasImage: _controller.gstImagePath != null,
                onTap: () async {
                  await _controller.pickImage(false);
                  setState(() {});
                },
              ),

              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textGrey,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildRoleSelector() {
    // Public sign-up: buyer / seller / transporter (admins are created by admins).
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RegisterController.roles.entries.map((entry) {
        final selected = _controller.selectedRole == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          selectedColor: AppColors.primaryBrand.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: selected ? AppColors.primaryBrand : AppColors.textGrey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(color: selected ? AppColors.primaryBrand : AppColors.border),
          onSelected: (_) => setState(() => _controller.selectedRole = entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryBrand, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: AppColors.border, height: 1),
      ],
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          style: TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade700),
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryBrand),
            ),
          ),
          validator: (value) => value!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade700),
            filled: true,
            fillColor: AppColors.cardSurface,
            suffixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryBrand),
            ),
          ),
          validator: (value) => value!.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: AppColors.cardSurface,
          style: TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryBrand),
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item[0].toUpperCase() + item.substring(1)),
          )).toList(),
          onChanged: onChanged,
          icon: Icon(IconlyLight.arrow_down_2, color: Colors.grey.shade600),
          validator: (val) => val == null ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required bool hasImage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF132238),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryBrand),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  if (hasImage)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "UPLOADED",
                        style: TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Text(
                      "Tap to upload",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(
              hasImage ? IconlyLight.show : IconlyLight.upload,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrand,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppColors.primaryBrand.withOpacity(0.4),
        ),
        onPressed: _controller.isLoading
            ? null
            : () async {
                setState(() => _controller.isLoading = true);
                try {
                  final user = await _controller.register();
                  if (user != null) {
                    if(mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Registration Successful")),
                      );
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
                setState(() => _controller.isLoading = false);
              },
        child: _controller.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Confirm Registration",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(IconlyLight.tick_square, color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}
