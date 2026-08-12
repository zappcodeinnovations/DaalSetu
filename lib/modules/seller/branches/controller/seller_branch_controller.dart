import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_branch_model.dart';

class SellerBranchController extends GetxController {
  var isLoading = false.obs;
  var primaryBranch = Rxn<SellerBranchModel>();
  var myBranches = <SellerBranchModel>[].obs;
  var pendingRequests = <SellerBranchModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading.value = true;
      final res = await SellerServices.getSellerBranches();
      if (res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;
        if (data['primary_branch'] is Map<String, dynamic>) {
          primaryBranch.value = SellerBranchModel.fromJson(data['primary_branch']);
        }
        if (data['my_branches'] is List) {
          myBranches.value = (data['my_branches'] as List).map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (data['pending_requests'] is List) {
          pendingRequests.value = (data['pending_requests'] as List).map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinBranchByCode(String code) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.requestBranchByCode(code);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Branch request submitted successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchBranches();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> cancelRequest(int branchId) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.cancelBranchRequest(branchId);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Request cancelled successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchBranches();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> leaveBranch(int branchId) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.leaveBranch(branchId);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Left branch successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchBranches();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> createBranch({required String locationName, required String city, required String state, required String area}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final body = {
        "location_name": locationName,
        "city": city,
        "state": state,
        "area": area,
      };
      final res = await SellerServices.createBranch(body);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Branch created successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchBranches();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
