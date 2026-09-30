import '../../../services/kyc_users_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/kyc_user_model.dart';

class KycController extends GetxController {
  final isLoading = false.obs;
  final kycUsers = <KycUserModel>[].obs;
  final selectedFilter = "all".obs;
  final searchQuery = "".obs;

  int get pendingCount => kycUsers.where((u) => u.kycStatus.toLowerCase() == 'pending').length;
  int get approvedCount => kycUsers.where((u) => u.kycStatus.toLowerCase() == 'approved').length;
  int get rejectedCount => kycUsers.where((u) => u.kycStatus.toLowerCase() == 'rejected').length;
  int get totalCount => kycUsers.length;

  List<KycUserModel> get filteredUsers {
    return kycUsers.where((user) {
      // Filter by tab
      if (selectedFilter.value != 'all' && user.kycStatus.toLowerCase() != selectedFilter.value.toLowerCase()) {
        return false;
      }
      // Filter by search query
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        if (!user.name.toLowerCase().contains(query) && 
            !user.email.toLowerCase().contains(query) &&
            !user.mobile.toLowerCase().contains(query) &&
            !(user.companyName?.toLowerCase().contains(query) ?? false)) {
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

  void changeFilter(String filter) {
    selectedFilter.value = filter;
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final data = await KycService.fetchKycUsers();
      kycUsers.value = data;
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approve(int id) async {
    try {
      await KycService.approveKyc(id);
      await fetchUsers();
      Get.snackbar("Success", "KYC Approved");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> reject(int userId, String reason) async {
    try {
      isLoading(true);

      await KycService.rejectKyc(userId, reason);

      Get.snackbar(
        "Success",
        "KYC rejected successfully",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      fetchUsers(); // refresh list
    } catch (e) {
      Get.snackbar(
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
