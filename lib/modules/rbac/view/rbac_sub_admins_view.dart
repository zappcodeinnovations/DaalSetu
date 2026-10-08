import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/rbac_sub_admins_controller.dart';
import '../model/rbac_sub_admin_model.dart';

class RbacSubAdminsView extends StatefulWidget {
  const RbacSubAdminsView({super.key});

  @override
  State<RbacSubAdminsView> createState() => _RbacSubAdminsViewState();
}

class _RbacSubAdminsViewState extends State<RbacSubAdminsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RbacSubAdminsController controller = Get.put(RbacSubAdminsController());
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text(
          "Sub Admins",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Obx(() => Tab(
                  text: "All Sub Admins (${controller.subAdmins.length})",
                  icon: const Icon(IconlyLight.user),
                )),
            const Tab(
              text: "Create Sub Admin",
              icon: Icon(IconlyLight.plus),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSubAdminsTab(context),
          _buildCreateSubAdminTab(context),
        ],
      ),
    );
  }

  Widget _buildAllSubAdminsTab(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      if (controller.isLoading.value && controller.subAdmins.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.fetchSubAdmins();
          await controller.fetchRoles();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Add Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search name, mobile, email, branch...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        prefixIcon: const Icon(IconlyLight.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: theme.cardColor.withValues(alpha: 0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.resetForm();
                      _tabController.animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("+ Create", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (controller.filteredSubAdmins.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(IconlyLight.user_1, size: 50, color: primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No Sub Admins created yet.",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Add team members to delegate access to branches, offers, or deals.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            controller.resetForm();
                            _tabController.animateTo(1);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Create Sub Admin"),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredSubAdmins.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final subAdmin = controller.filteredSubAdmins[index];
                    return _buildSubAdminCard(context, subAdmin);
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSubAdminCard(BuildContext context, RbacSubAdminModel subAdmin) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Text(
                  subAdmin.fullName.isNotEmpty ? subAdmin.fullName[0].toUpperCase() : "U",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subAdmin.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (subAdmin.company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(IconlyLight.work, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subAdmin.company,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status Badge / Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subAdmin.isActive ? "Active" : "Inactive",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: subAdmin.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Switch(
                        value: subAdmin.isActive,
                        activeColor: Colors.green,
                        onChanged: (_) => controller.toggleSubAdminStatus(subAdmin.id, subAdmin.isActive),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Details Grid
          Row(
            children: [
              if (subAdmin.mobile.isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(IconlyLight.call, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        subAdmin.mobile,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              if (subAdmin.branchRefCode.isNotEmpty)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(IconlyLight.location, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        "Branch: ${subAdmin.branchRefCode}",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (subAdmin.email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(IconlyLight.message, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  subAdmin.email,
                  style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Roles Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ROLES",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              IconButton(
                icon: Icon(IconlyLight.delete, size: 18, color: theme.colorScheme.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: "Delete Sub Admin",
                onPressed: () => _confirmDeleteSubAdmin(context, subAdmin),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (subAdmin.roles.isEmpty)
            Text(
              "No specific role assigned",
              style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: subAdmin.roles.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    r,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateSubAdminTab(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Sub Admin",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final success = await controller.createSubAdmin();
                        if (success) {
                          _tabController.animateTo(0);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC05621), // Rust/Orange button matching screenshot
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
    });
  }

  void _confirmDeleteSubAdmin(BuildContext context, RbacSubAdminModel subAdmin) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Delete Sub Admin?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove sub admin '${subAdmin.fullName}'?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Get.back();
              controller.deleteSubAdmin(subAdmin.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
