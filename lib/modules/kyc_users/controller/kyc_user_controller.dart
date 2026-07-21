import 'package:agro_broker/services/kyc_users_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/kyc_user_model.dart';

class KycController extends GetxController {
  final isLoading = false.obs;
  final kycUsers = <KycUserModel>[].obs;
  final selectedFilter = "all".obs;

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
