import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/app_snackbar.dart';
import '../controller/rbac_sub_admins_controller.dart';

class CreateSubAdminView extends StatefulWidget {
  const CreateSubAdminView({super.key});

  @override
  State<CreateSubAdminView> createState() => _CreateSubAdminViewState();
}

class _CreateSubAdminViewState extends State<CreateSubAdminView> {
  late final RbacSubAdminsController controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<RbacSubAdminsController>()
        ? Get.find<RbacSubAdminsController>()
        : Get.put(RbacSubAdminsController());
    controller.resetForm();
    controller.fetchRoles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.bodyLarge?.color, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Create Sub Admin",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Name & Last Name
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("First Name *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.firstNameController,
                          decoration: InputDecoration(
                            hintText: "First Name",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: theme.cardColor.withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Last Name", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.lastNameController,
                          decoration: InputDecoration(
                            hintText: "Last Name",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: theme.cardColor.withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email & Mobile
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "staff@example.com",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: theme.cardColor.withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mobile *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: "9876543210",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: theme.cardColor.withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password
              Text("Password *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: controller.passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Login password for sub-admin",
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: theme.cardColor.withValues(alpha: 0.6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Branch Ref Code & Company
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Branch Ref Code", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.branchRefCodeController,
                          decoration: InputDecoration(
                            hintText: "AMA462M",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: theme.cardColor.withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Company *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: controller.companyController,
                          decoration: InputDecoration(
                            hintText: "Farmland (Primary)",
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                            filled: true,
                            fillColor: theme.cardColor.withValues(alpha: 0.6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Roles Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Roles", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.rbacRoles),
                    child: const Text("Manage Roles", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (controller.availableRoles.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(IconlyLight.info_square, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Create a role first from Settings > Roles.",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.rbacRoles),
                        child: const Text("+ Create Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.availableRoles.map((role) {
                    final isSelected = controller.selectedRoleIds.contains(role.id);
                    return FilterChip(
                      label: Text(role.name),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) => controller.toggleRoleSelection(role),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          final fName = controller.firstNameController.text.trim();
                          final lName = controller.lastNameController.text.trim();
                          final success = await controller.createSubAdmin();
                          if (success) {
                            Get.back();
                            AppSnackbar.showSuccess(
                              title: "Sub Admin Created",
                              message: "New sub admin '$fName $lName' created successfully.",
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC05621), // Rust/Amber button matching web
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "+ Create Sub Admin",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
