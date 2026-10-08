import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/rbac_roles_controller.dart';
import '../model/rbac_role_model.dart';

class CreateRoleView extends StatefulWidget {
  final RbacRoleModel? roleToEdit;
  const CreateRoleView({super.key, this.roleToEdit});

  @override
  State<CreateRoleView> createState() => _CreateRoleViewState();
}

class _CreateRoleViewState extends State<CreateRoleView> {
  late final RbacRolesController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<RbacRolesController>()
        ? Get.find<RbacRolesController>()
        : Get.put(RbacRolesController());

    if (widget.roleToEdit != null) {
      controller.startEditRole(widget.roleToEdit!);
    } else {
      controller.resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Obx(() {
      final isEditing = controller.editingRole.value != null;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textTheme.bodyLarge?.color, size: 20),
            onPressed: () {
              controller.resetForm();
              Get.back();
            },
          ),
          title: Text(
            isEditing ? "Edit Role" : "Create Role",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    final isSelected = controller.selectedPanel.value.key == panel.key ||
                        controller.selectedPanel.value.name == panel.name;
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
                          final isAllowed = controller.isPermissionEnabled(item.id);
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
                                        onChanged: (_) => controller.togglePermission(item.id),
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
                            Get.back();
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
        ),
      );
    });
  }
}
