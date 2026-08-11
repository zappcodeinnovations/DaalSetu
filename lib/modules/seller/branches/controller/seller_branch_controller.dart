import '../model/seller_branch_model.dart';
import 'package:agro_broker/services/seller_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerBranchController extends GetxController {
  var isLoading = true.obs;
  var branchData = Rxn<SellerBranchesResponse>();

  final branchCodeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading(true);
      final data = await SellerServices.getBranches();
      branchData.value = SellerBranchesResponse.fromJson(data);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> joinBranch() async {
    final code = branchCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar("Error", "Please enter branch code");
      return;
    }

    try {
      isLoading(true);
      await SellerServices.requestJoinBranch(code);
      branchCodeController.clear();
      Get.back();
      Get.snackbar("Success", "Join request sent successfully");
      fetchBranches();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> leaveBranch(int id) async {
    try {
      isLoading(true);
      await SellerServices.leaveBranch(id);
      Get.snackbar("Success", "Left branch successfully");
      fetchBranches();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> cancelRequest(int id) async {
    try {
      isLoading(true);
      await SellerServices.cancelBranchRequest(id);
      Get.snackbar("Success", "Request cancelled");
      fetchBranches();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    branchCodeController.dispose();
    super.onClose();
  }
}
