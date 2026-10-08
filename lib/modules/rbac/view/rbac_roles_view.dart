import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/rbac_roles_controller.dart';
import '../model/rbac_role_model.dart';

class RbacRolesView extends StatefulWidget {
  const RbacRolesView({super.key});

  @override
  State<RbacRolesView> createState() => _RbacRolesViewState();
}

class _RbacRolesViewState extends State<RbacRolesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RbacRolesController controller = Get.put(RbacRolesController());

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
          "Role Management",
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
                  text: "All Roles (${controller.roles.length})",
                  icon: const Icon(IconlyLight.user),
                )),
            Obx(() => Tab(
                  text: controller.editingRole.value != null ? "Edit Role" : "Create Role",
                  icon: Icon(controller.editingRole.value != null ? IconlyLight.edit : IconlyLight.plus),
                )),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllRolesTab(context),
          _buildCreateRoleTab(context),
        ],
      ),
    );
  }

  Widget _buildAllRolesTab(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      if (controller.isLoading.value && controller.roles.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: controller.fetchRoles,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Add Header
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
                    label: const Text("+ New Role", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (controller.filteredRoles.isEmpty)
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
                          child: Icon(IconlyLight.shield_done, size: 50, color: primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No roles created yet.",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Define role permissions to assign to sub admins.",
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
                          label: const Text("Create First Role"),
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
                    return _buildRoleCard(context, role);
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRoleCard(BuildContext context, RbacRoleModel role) {
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
                  controller.startEditRole(role);
                  _tabController.animateTo(1);
                },
              ),
              IconButton(
                icon: Icon(IconlyLight.delete, size: 20, color: theme.colorScheme.error),
                tooltip: "Delete Role",
                onPressed: () => _confirmDeleteRole(context, role),
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

  Widget _buildCreateRoleTab(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      final isEditing = controller.editingRole.value != null;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? "Edit Role" : "Create Role",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEditing)
                  TextButton.icon(
                    onPressed: () => controller.resetForm(),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Cancel Edit"),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Role Name
            Text("Role Name *", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                hintText: "e.g. HR, Sales, Accountant",
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: theme.cardColor.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text("Description", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Optional description...",
                hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                filled: true,
                fillColor: theme.cardColor.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Permission Panel Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PERMISSION PANEL",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  "Toggle access for selected panel",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Panel selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.panels.map((panel) {
                  final isSelected = controller.selectedPanel.value.name == panel.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(panel.name),
                      selected: isSelected,
                      selectedColor: primaryColor,
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) controller.setPanel(panel);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Groups under the selected panel
            ...controller.selectedPanel.value.groups.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            group.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${group.items.length}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      ...group.items.map((item) {
                        final isAllowed = controller.isPermissionEnabled(item.code);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAllowed
                                  ? primaryColor.withValues(alpha: 0.08)
                                  : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isAllowed ? primaryColor.withValues(alpha: 0.4) : theme.dividerColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isAllowed ? FontWeight.w600 : FontWeight.w400,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      isAllowed ? "Allow" : "Deny",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isAllowed ? primaryColor : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Switch(
                                      value: isAllowed,
                                      activeColor: primaryColor,
                                      onChanged: (_) => controller.togglePermission(item.code),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Save / Update Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () async {
                        final success = await controller.saveRole();
                        if (success) {
                          _tabController.animateTo(0);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC05621), // Rust/Amber web button color
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
                        isEditing ? "Update Role" : "Save Role",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _confirmDeleteRole(BuildContext context, RbacRoleModel role) {
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
