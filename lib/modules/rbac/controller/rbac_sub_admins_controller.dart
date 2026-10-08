import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/rbac_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../profile/controller/profile_controller.dart';
import '../model/rbac_role_model.dart';
import '../model/rbac_sub_admin_model.dart';

class RbacSubAdminsController extends GetxController {
  var isLoading = false.obs;
  var isSaving = false.obs;
  var subAdmins = <RbacSubAdminModel>[].obs;
  var availableRoles = <RbacRoleModel>[].obs;
  var searchQuery = ''.obs;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final branchRefCodeController = TextEditingController();
  final companyController = TextEditingController();
  final searchController = TextEditingController();

  final selectedRoleIds = <int>[].obs;
  final selectedRoleNames = <String>[].obs;

  List<RbacSubAdminModel> get filteredSubAdmins {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return subAdmins;
    return subAdmins.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.mobile.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          s.company.toLowerCase().contains(q) ||
          s.branchRefCode.toLowerCase().contains(q) ||
          s.roles.any((r) => r.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchSubAdmins();
    fetchRoles();
    _autoFillDefaults();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    branchRefCodeController.dispose();
    companyController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> _autoFillDefaults() async {
    try {
      if (Get.isRegistered<ProfileController>()) {
        final profile = Get.find<ProfileController>().profile.value;
        if (profile != null) {
          if (profile.firstName.isNotEmpty && firstNameController.text.isEmpty) {
            // we leave first name empty for creating new staff sub-admin
          }
        }
      }

      // Load branch or company from buyer dashboard / preferences
      if (branchRefCodeController.text.isEmpty || companyController.text.isEmpty) {
        final dash = await BuyerServices.getDashboard();
        final actual = dash['body'] ?? dash;
        if (actual is Map) {
          final bCode = actual['branch_code'] ?? actual['branchRefCode'] ?? actual['branch'] ?? actual['branch_ref_code'];
          if (bCode != null && branchRefCodeController.text.isEmpty) {
            branchRefCodeController.text = bCode.toString();
          }
          final cName = actual['company_name'] ?? actual['company'] ?? actual['primary_company'] ?? actual['registered_company'];
          if (cName != null && companyController.text.isEmpty) {
            companyController.text = cName.toString();
          }
        }
      }
    } catch (_) {}

    if (branchRefCodeController.text.isEmpty) {
      branchRefCodeController.text = "AMA462M";
    }
    if (companyController.text.isEmpty) {
      companyController.text = "Farmland (Primary)";
    }
  }

  Future<void> fetchSubAdmins() async {
    try {
      isLoading.value = true;
      final list = await RbacServices.getSubAdmins();
      subAdmins.assignAll(list);
    } catch (e) {
      print("Sub-Admins fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRoles() async {
    try {
      final list = await RbacServices.getRoles();
      availableRoles.assignAll(list);
    } catch (_) {}
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void toggleRoleSelection(RbacRoleModel role) {
    if (selectedRoleIds.contains(role.id)) {
      selectedRoleIds.remove(role.id);
      selectedRoleNames.remove(role.name);
    } else {
      selectedRoleIds.add(role.id);
      selectedRoleNames.add(role.name);
    }
  }

  void resetForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    mobileController.clear();
    passwordController.clear();
    selectedRoleIds.clear();
    selectedRoleNames.clear();
    _autoFillDefaults();
  }

  Future<bool> createSubAdmin() async {
    final fName = firstNameController.text.trim();
    final lName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();
    final password = passwordController.text.trim();
    final branchCode = branchRefCodeController.text.trim();
    final company = companyController.text.trim();

    if (fName.isEmpty) {
      AppSnackbar.showWarning(title: "First Name Required", message: "Please enter first name");
      return false;
    }
    if (mobile.isEmpty && email.isEmpty) {
      AppSnackbar.showWarning(title: "Contact Info Required", message: "Please enter a mobile number or email");
      return false;
    }
    if (password.isEmpty) {
      AppSnackbar.showWarning(title: "Password Required", message: "Please enter a login password for the sub-admin");
      return false;
    }

    try {
      isSaving.value = true;
      final effectiveRoleIds = selectedRoleIds.isNotEmpty
          ? selectedRoleIds.toList()
          : (availableRoles.isNotEmpty ? [availableRoles.first.id] : [1]);

      await RbacServices.createSubAdmin(
        firstName: fName,
        lastName: lName,
        email: email,
        mobile: mobile,
        password: password,
        branchRefCode: branchCode,
        company: company,
        companyId: 98,
        roleIds: effectiveRoleIds,
        roles: selectedRoleNames.isNotEmpty ? selectedRoleNames.toList() : ["Sub Admin"],
      );

      await fetchSubAdmins();
      return true;
    } catch (e) {
      AppSnackbar.showError(title: "Failed to Create Sub Admin", message: e.toString().replaceAll("Exception: ", ""));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleSubAdminStatus(int id, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      // Optimistic update
      final index = subAdmins.indexWhere((s) => s.id == id);
      if (index != -1) {
        final old = subAdmins[index];
        subAdmins[index] = RbacSubAdminModel(
          id: old.id,
          firstName: old.firstName,
          lastName: old.lastName,
          email: old.email,
          mobile: old.mobile,
          branchRefCode: old.branchRefCode,
          company: old.company,
          roles: old.roles,
          isActive: newStatus,
          createdAt: old.createdAt,
        );
      }

      await RbacServices.toggleSubAdminStatus(id, newStatus);
      AppSnackbar.showSuccess(
        title: "Status Updated",
        message: "Sub admin is now ${newStatus ? 'Active' : 'Inactive'}.",
      );
    } catch (e) {
      await fetchSubAdmins();
      AppSnackbar.showError(title: "Status Update Failed", message: e.toString().replaceAll("Exception: ", ""));
    }
  }

  Future<void> deleteSubAdmin(int id) async {
    try {
      isLoading.value = true;
      await RbacServices.deleteSubAdmin(id);
      subAdmins.removeWhere((s) => s.id == id);
      AppSnackbar.showSuccess(title: "Sub Admin Removed", message: "The sub admin account was deleted.");
    } catch (e) {
      AppSnackbar.showError(title: "Delete Failed", message: e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }
}
