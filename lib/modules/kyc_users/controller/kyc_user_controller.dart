import '../../../services/kyc_users_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/kyc_user_model.dart';
import '../../../utils/app_snackbar.dart';

class KycController extends GetxController {
  final isLoading = false.obs;
  final kycUsers = <KycUserModel>[].obs;
  final selectedFilter = "all".obs;
  final selectedRole = "all".obs;
  final searchQuery = "".obs;
  final searchController = TextEditingController();

  int get pendingCount => kycUsers.where((u) => u.kycStatus.toLowerCase() == 'pending').length;
  int get approvedCount => kycUsers.where((u) => u.kycStatus.toLowerCase() == 'approved').length;
  int get rejectedCount => kycUsers.where((u) => u.kycStatus.toLowerCase() == 'rejected').length;
  int get totalCount => kycUsers.length;

  List<KycUserModel> get filteredUsers {
    return kycUsers.where((user) {
      // Filter by tab / status
      if (selectedFilter.value != 'all' &&
          user.kycStatus.trim().toLowerCase() != selectedFilter.value.trim().toLowerCase()) {
        return false;
      }
      // Filter by role
      if (selectedRole.value != 'all') {
        final selRole = selectedRole.value.trim().toLowerCase().replaceAll('_', '');
        final userRole = user.role.trim().toLowerCase().replaceAll('_', '');
        if (userRole.isNotEmpty && !userRole.contains(selRole)) {
          return false;
        }
      }
      // Filter by search query
      if (searchQuery.value.trim().isNotEmpty) {
        final query = searchQuery.value.trim().toLowerCase();
        final matches = user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.mobile.toLowerCase().contains(query) ||
            user.role.toLowerCase().contains(query) ||
            (user.panNumber?.toLowerCase().contains(query) ?? false) ||
            (user.gstNumber?.toLowerCase().contains(query) ?? false) ||
            (user.companyName?.toLowerCase().contains(query) ?? false) ||
            (user.branchName?.toLowerCase().contains(query) ?? false);
        if (!matches) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
    fetchUsers(status: filter);
  }

  void setRoleFilter(String role) {
    selectedRole.value = role;
    fetchUsers(role: role);
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchUsers(search: '');
  }

  void resetFilters() {
    selectedRole.value = 'all';
    selectedFilter.value = 'all';
    searchController.clear();
    searchQuery.value = '';
    fetchUsers(search: '', role: 'all', status: 'all');
  }

  Future<void> fetchUsers({String? search, String? role, String? status}) async {
    try {
      isLoading.value = true;
      final data = await KycService.fetchKycUsers(
        search: search ?? searchQuery.value,
        role: role ?? selectedRole.value,
        status: status ?? selectedFilter.value,
      );
      kycUsers.value = data;
    } catch (e) {
      if (Get.context != null) {
        AppSnackbar.snackbar("Error", e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approve(int id) async {
    try {
      await KycService.approveKyc(id);
      await fetchUsers();
      AppSnackbar.snackbar("Success", "KYC Approved");
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
    }
  }

  Future<void> reject(int userId, String reason) async {
    try {
      isLoading(true);

      await KycService.rejectKyc(userId, reason);

      AppSnackbar.snackbar(
        "Success",
        "KYC rejected successfully",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      fetchUsers(); // refresh list
    } catch (e) {
      AppSnackbar.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }
}
