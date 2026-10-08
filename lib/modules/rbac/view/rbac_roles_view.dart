import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/rbac_roles_controller.dart';
import '../model/rbac_role_model.dart';
import 'create_role_view.dart';

class RbacRolesView extends StatelessWidget {
  const RbacRolesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final RbacRolesController controller = Get.put(RbacRolesController());

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
          "Role Management",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const CreateRoleView());
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          "Create Role",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.roles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.fetchRoles,
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
                    hintText: "Search roles or permissions...",
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

                if (controller.filteredRoles.isEmpty)
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
                            child: Icon(IconlyLight.shield_done, size: 52, color: primaryColor),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "No roles created yet.",
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the '+ Create Role' button below to define custom permissions for staff sub-admins.",
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
                    itemCount: controller.filteredRoles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final role = controller.filteredRoles[index];
                      return _buildRoleCard(context, controller, role);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoleCard(
    BuildContext context,
    RbacRolesController controller,
    RbacRoleModel role,
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(IconlyBold.shield_done, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (role.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action Buttons
              IconButton(
                icon: const Icon(IconlyLight.edit, size: 20),
                tooltip: "Edit Role",
                onPressed: () {
                  Get.to(() => CreateRoleView(roleToEdit: role));
                },
              ),
              IconButton(
                icon: Icon(IconlyLight.delete, size: 20, color: theme.colorScheme.error),
                tooltip: "Delete Role",
                onPressed: () => _confirmDeleteRole(context, controller, role),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PERMISSIONS (${role.permissions.length})",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              if (role.subAdminsCount != null)
                Text(
                  "${role.subAdminsCount} Assigned",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (role.permissions.isEmpty)
            Text(
              "No specific permissions assigned (All Denied)",
              style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: role.permissions.map((p) {
                final display = p.replaceAll('_', ' ').capitalizeFirst ?? p;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    display,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  void _confirmDeleteRole(
    BuildContext context,
    RbacRolesController controller,
    RbacRoleModel role,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Delete Role?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete role '${role.name}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Get.back();
              controller.deleteRole(role.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
