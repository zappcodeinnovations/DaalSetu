import '../model/buyer_challan_model.dart';
import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
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
      final list = (data['results'] as List?) ?? (data['challans'] as List?) ?? (data['data'] as List?) ?? [];
      challans.assignAll(list.map((e) => BuyerChallanModel.fromJson(e)).toList());
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: e.toString());
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
      AppSnackbar.showError(title: "Error", message: "Could not fetch details");
    } finally {
      isDetailLoading(false);
    }
  }

  Future<void> markAsReceived(int id, String remarks) async {
    try {
      isLoading(true);
      await BuyerServices.receiveChallan(id, remarks);
      AppSnackbar.showSuccess(title: "Success", message: "Shipment received successfully");
      fetchChallans();
      if (selectedChallan.value != null && selectedChallan.value!['id'] == id) {
        fetchChallanDetails(id);
      }
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: e.toString());
    } finally {
      isLoading(false);
    }
  }
}
