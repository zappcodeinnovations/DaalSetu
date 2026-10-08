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

  final panels = PermissionPanel.getDefaultPanels();
  late final Rx<PermissionPanel> selectedPanel;

  final selectedPermissions = <String>{}.obs;

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
          r.permissions.any((p) => p.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    selectedPanel = panels.first.obs;
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
      final list = await RbacServices.getRoles();
      roles.assignAll(list);
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

  bool isPermissionEnabled(String code) {
    return selectedPermissions.contains(code);
  }

  void togglePermission(String code) {
    if (selectedPermissions.contains(code)) {
      selectedPermissions.remove(code);
    } else {
      selectedPermissions.add(code);
    }
  }

  void resetForm() {
    editingRole.value = null;
    nameController.clear();
    descController.clear();
    selectedPermissions.clear();
  }

  void startEditRole(RbacRoleModel role) {
    editingRole.value = role;
    nameController.text = role.name;
    descController.text = role.description;
    selectedPermissions.assignAll(role.permissions);
  }

  Future<bool> saveRole() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.showWarning(title: "Role Name Required", message: "Please enter a role name (e.g. Sales, HR, Accountant)");
      return false;
    }

    try {
      isSaving.value = true;
      if (editingRole.value != null) {
        await RbacServices.updateRole(
          id: editingRole.value!.id,
          name: name,
          description: descController.text.trim(),
          permissions: selectedPermissions.toList(),
        );
        AppSnackbar.showSuccess(title: "Role Updated", message: "Role '$name' was updated successfully.");
      } else {
        await RbacServices.createRole(
          name: name,
          description: descController.text.trim(),
          permissions: selectedPermissions.toList(),
        );
        AppSnackbar.showSuccess(title: "Role Created", message: "New role '$name' created successfully.");
      }

      resetForm();
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
