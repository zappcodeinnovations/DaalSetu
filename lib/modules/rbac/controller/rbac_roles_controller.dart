import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/rbac_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../model/rbac_role_model.dart';

class RbacRolesController extends GetxController {
  var isLoading = false.obs;
  var isSaving = false.obs;
  var roles = <RbacRoleModel>[].obs;
  var searchQuery = ''.obs;

  final panels = <PermissionPanel>[].obs;
  late final Rx<PermissionPanel> selectedPanel;

  final selectedPermissionIds = <int>{}.obs;

  final nameController = TextEditingController();
  final descController = TextEditingController();
  final searchController = TextEditingController();

  Rxn<RbacRoleModel> editingRole = Rxn<RbacRoleModel>();

  List<RbacRoleModel> get filteredRoles {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return roles;
    return roles.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q) ||
          r.slug.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    final defaults = PermissionPanel.getDefaultPanels();
    panels.assignAll(defaults);
    selectedPanel = defaults.first.obs;
    fetchRoles();
  }

  @override
  void onClose() {
    nameController.dispose();
    descController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchRoles() async {
    try {
      isLoading.value = true;
      final res = await RbacServices.getRolesWithCategories();
      roles.assignAll(res.roles);
      if (res.panels.isNotEmpty) {
        panels.assignAll(res.panels);
        // keep current selected panel or set to first
        final currentKey = selectedPanel.value.key;
        final matched = panels.firstWhereOrNull((p) => p.key == currentKey);
        selectedPanel.value = matched ?? panels.first;
      }
    } catch (e) {
      print("Roles fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void setPanel(PermissionPanel panel) {
    selectedPanel.value = panel;
  }

  bool isPermissionEnabled(int id) {
    return selectedPermissionIds.contains(id);
  }

  void togglePermission(int id) {
    if (selectedPermissionIds.contains(id)) {
      selectedPermissionIds.remove(id);
    } else {
      selectedPermissionIds.add(id);
    }
  }

  void resetForm() {
    editingRole.value = null;
    nameController.clear();
    descController.clear();
    selectedPermissionIds.clear();
  }

  Future<void> startEditRole(RbacRoleModel role) async {
    editingRole.value = role;
    nameController.text = role.name;
    descController.text = role.description;
    selectedPermissionIds.clear();
    selectedPermissionIds.addAll(role.permissionIds);

    // If role has string permissions or code names, map them to item.id
    if (role.permissions.isNotEmpty) {
      for (var panel in panels) {
        for (var grp in panel.groups) {
          for (var item in grp.items) {
            if (role.permissions.contains(item.code) ||
                role.permissions.contains(item.label) ||
                role.permissions.contains(item.id.toString())) {
              selectedPermissionIds.add(item.id);
            }
          }
        }
      }
    }

    try {
      final detail = await RbacServices.getRoleDetails(role.id);
      if (detail != null) {
        if (detail.permissionIds.isNotEmpty) {
          selectedPermissionIds.addAll(detail.permissionIds);
        }
        if (detail.permissions.isNotEmpty) {
          for (var panel in panels) {
            for (var grp in panel.groups) {
              for (var item in grp.items) {
                if (detail.permissions.contains(item.code) ||
                    detail.permissions.contains(item.label) ||
                    detail.permissions.contains(item.id.toString())) {
                  selectedPermissionIds.add(item.id);
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<bool> saveRole() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.showWarning(title: "Role Name Required", message: "Please enter a role name (e.g. Sales, HR, Accountant)");
      return false;
    }

    try {
      isSaving.value = true;
      final ids = selectedPermissionIds.toList();
      final codes = <String>[];
      for (var id in ids) {
        for (var panel in panels) {
          for (var grp in panel.groups) {
            for (var item in grp.items) {
              if (item.id == id && item.code.isNotEmpty) {
                codes.add(item.code);
              }
            }
          }
        }
      }

      if (editingRole.value != null) {
        await RbacServices.updateRole(
          id: editingRole.value!.id,
          name: name,
          description: descController.text.trim(),
          permissionIds: ids,
          permissionCodes: codes,
        );
      } else {
        await RbacServices.createRole(
          name: name,
          description: descController.text.trim(),
          permissionIds: ids,
          permissionCodes: codes,
        );
      }

      await fetchRoles();
      return true;
    } catch (e) {
      AppSnackbar.showError(title: "Failed to Save Role", message: e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteRole(int roleId) async {
    try {
      isLoading.value = true;
      await RbacServices.deleteRole(roleId);
      roles.removeWhere((r) => r.id == roleId);
      AppSnackbar.showSuccess(title: "Role Deleted", message: "The role was removed successfully.");
    } catch (e) {
      AppSnackbar.showError(title: "Delete Failed", message: e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }
}
