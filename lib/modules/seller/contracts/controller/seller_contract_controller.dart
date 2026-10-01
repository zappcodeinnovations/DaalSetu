import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_contract_model.dart';

class SellerContractController extends GetxController {
  var isLoading = false.obs;
  var contractsList = <SellerContractModel>[].obs;
  List<SellerContractModel> get contracts => contractsList;

  @override
  void onInit() {
    super.onInit();
    fetchContracts();
  }

  Future<void> fetchContracts() async {
    try {
      isLoading.value = true;
      final data = await SellerServices.getSellerContracts();
      contractsList.value = data.map((e) => SellerContractModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
