import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_challan_model.dart';
import '../../../../utils/app_snackbar.dart';

class SellerChallanController extends GetxController {
  var isLoading = false.obs;
  var challansList = <SellerChallanModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchChallans();
  }

  Future<void> fetchChallans() async {
    try {
      isLoading.value = true;
      final data = await SellerServices.getDeliveryChallans();
      challansList.value = data.map((e) => SellerChallanModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> dispatchChallan(int challanId) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.dispatchDeliveryChallan(challanId);
      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.snackbar("Success", res['message'] ?? "Challan dispatched successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchChallans();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      AppSnackbar.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
