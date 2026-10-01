import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_rfq_model.dart';

class SellerRfqController extends GetxController {
  var isLoading = false.obs;
  var rfqList = <SellerRfqModel>[].obs;
  var searchQuery = ''.obs;
  var selectedCategoryId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRFQs();
  }

  Future<void> fetchRFQs() async {
    try {
      isLoading.value = true;
      final data = await SellerServices.getBuyerRFQs(
        categoryId: selectedCategoryId.value.isNotEmpty ? selectedCategoryId.value : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );
      rfqList.value = data.map((e) => SellerRfqModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitQuote(
    int rfqId, {
    required String quotedPrice,
    required String offeredQuantity,
    required int bagCount,
    required String packingWeight,
    String? remarks,
  }) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final body = {
        "offered_price": quotedPrice,
        "quoted_price": quotedPrice,
        "offered_quantity": offeredQuantity,
        "bag_count": bagCount,
        "packing_weight_kg": packingWeight,
        if (remarks != null && remarks.isNotEmpty) "seller_remark": remarks,
        if (remarks != null && remarks.isNotEmpty) "remarks": remarks,
      };
      final res = await SellerServices.submitRFQQuote(rfqId, body);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Quote submitted successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchRFQs();
      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }
}
