import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/rbac_sub_admins_controller.dart';
import '../model/rbac_sub_admin_model.dart';
import 'create_sub_admin_view.dart';

class RbacSubAdminsView extends StatelessWidget {
  const RbacSubAdminsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final RbacSubAdminsController controller = Get.put(RbacSubAdminsController());

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
          "Sub Admins",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.to(() => const CreateSubAdminView());
          controller.fetchSubAdmins();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          "Create Sub Admin",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Obx(() {
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Width Search Bar
                TextField(
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
                const SizedBox(height: 20),

                if (controller.filteredSubAdmins.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(IconlyLight.user_1, size: 52, color: primaryColor),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "No Sub Admins created yet.",
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the '+ Create Sub Admin' button below to add your first staff sub-admin.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
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
                      return _buildSubAdminCard(context, controller, subAdmin);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubAdminCard(
    BuildContext context,
    RbacSubAdminsController controller,
    RbacSubAdminModel subAdmin,
  ) {
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
                        activeThumbColor: Colors.green,
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
                onPressed: () => _confirmDeleteSubAdmin(context, controller, subAdmin),
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

  void _confirmDeleteSubAdmin(
    BuildContext context,
    RbacSubAdminsController controller,
    RbacSubAdminModel subAdmin,
  ) {
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
