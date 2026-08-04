import 'package:agro_broker/modules/buyer/delivery_challan/model/buyer_challan_model.dart';
import 'package:agro_broker/services/buyer_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BuyerDeliveryController extends GetxController {
  var isLoading = true.obs;
  var isDetailLoading = false.obs;
  var challans = <BuyerChallanModel>[].obs;
  var selectedChallan = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchChallans();
  }

  Future<void> fetchChallans() async {
    try {
      isLoading(true);
      final data = await BuyerServices.getDeliveryChallans();
      challans.assignAll(data.map((e) => BuyerChallanModel.fromJson(e)).toList());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchChallanDetails(int id) async {
    try {
      isDetailLoading(true);
      final data = await BuyerServices.getChallanDetails(id);
      selectedChallan.value = data;
    } catch (e) {
      Get.snackbar("Error", "Could not fetch details");
    } finally {
      isDetailLoading(false);
    }
  }

  Future<void> markAsReceived(int id, String remarks) async {
    try {
      isLoading(true);
      await BuyerServices.receiveChallan(id, remarks);
      Get.snackbar("Success", "Shipment received successfully");
      fetchChallans();
      if (selectedChallan.value != null && selectedChallan.value!['id'] == id) {
        fetchChallanDetails(id);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }
}
