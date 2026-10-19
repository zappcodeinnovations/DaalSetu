import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../network/api_client.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_branch_model.dart';
import '../../../../utils/app_snackbar.dart';

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
        // Replace every section, so a branch the server no longer returns
        // (left or removed) disappears instead of staying on screen.
        primaryBranch.value = data['primary_branch'] is Map<String, dynamic>
            ? SellerBranchModel.fromJson(data['primary_branch'])
            : null;
        myBranches.value = _branches(data['my_branches']);
        pendingRequests.value = _branches(data['pending_requests']);
      }
    } catch (e) {
      _showError('Could not load branches', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinBranchByCode(String code) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.requestBranchByCode(code);
      if (Get.isDialogOpen ?? false) Get.back();

      if (res['success'] == false) {
        _showError('Notice', res['message'] ?? 'Could not submit request');
        return;
      }
      AppSnackbar.snackbar(
        "Success",
        res['message'] ?? "Branch request submitted successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchBranches();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Invalid Branch Code', e);
    }
  }

  Future<void> cancelRequest(int branchId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.cancelBranchRequest(branchId);
      if (Get.isDialogOpen ?? false) Get.back();

      if (res['success'] == false) {
        _showError('Notice', res['message'] ?? 'Could not cancel request');
        return;
      }
      pendingRequests.removeWhere((item) => item.branchId == branchId);
      await fetchBranches();
      AppSnackbar.snackbar(
        "Success",
        res['message'] ?? "Request cancelled successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Could not cancel request', e);
    }
  }

  Future<void> leaveBranch(int branchId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.leaveBranch(branchId);
      if (Get.isDialogOpen ?? false) Get.back();

      final message = res['message']?.toString() ?? '';
      // Older servers answer "You are not added to this branch." with success.
      if (res['success'] == false || _isNotMemberMessage(message)) {
        await fetchBranches();
        _showNotice(message.isEmpty ? "Could not leave branch" : message);
        return;
      }

      myBranches.removeWhere(
        (item) => item.id == branchId || item.branchId == branchId,
      );
      await fetchBranches();
      AppSnackbar.snackbar(
        "Success",
        message.isEmpty ? "Left branch successfully" : message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      // 409 "not added" means the card was stale: reload so it disappears.
      await fetchBranches();
      _showNotice(ApiClient.userFriendlyErrorMessage(e.toString()));
    }
  }

  static List<SellerBranchModel> _branches(dynamic raw) => raw is List
      ? raw
            .whereType<Map<String, dynamic>>()
            .map(SellerBranchModel.fromJson)
            .toList()
      : <SellerBranchModel>[];

  static bool _isNotMemberMessage(String message) =>
      message.toLowerCase().contains('not added to this branch');

  void _showNotice(String message) {
    AppSnackbar.snackbar(
      "Notice",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<void> createBranch({
    required String locationName,
    required String city,
    required String state,
    required String area,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final body = {
        "location_name": locationName,
        "city": city,
        "state": state,
        "area": area,
      };
      final res = await SellerServices.createBranch(body);
      if (Get.isDialogOpen ?? false) Get.back();

      if (res['success'] == false) {
        _showError('Notice', res['message'] ?? 'Could not create branch');
        return;
      }
      AppSnackbar.snackbar(
        "Success",
        res['message'] ?? "Branch created successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchBranches();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showError('Could not create branch', e);
    }
  }

  void _showError(String title, Object error) {
    AppSnackbar.snackbar(
      title,
      ApiClient.userFriendlyErrorMessage(error.toString()),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
