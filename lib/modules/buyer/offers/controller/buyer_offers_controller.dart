import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/services/buyer_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BuyerOffersController extends GetxController {
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;

  var offersList = <BuyerOfferModel>[].obs;

  // The type of offers to fetch (e.g., 'all', 'today', 'pending', 'previous', 'interests')
  final String offerType;

  BuyerOffersController({required this.offerType});

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      isLoading(true);
      isError(false);
      offersList.clear();

      List<dynamic> data;

      switch (offerType) {
        case 'today':
          data = await BuyerServices.getTodayOffers();
          break;
        case 'pending':
          data = await BuyerServices.getPendingOffers();
          break;
        case 'previous':
          data = await BuyerServices.getPreviousOffers();
          break;
        case 'interests':
          data = await BuyerServices.getMyInterests();
          break;
        case 'all':
        default:
          data = await BuyerServices.getOffers();
          break;
      }

      offersList.value = data.map((e) => BuyerOfferModel.fromJson(e)).toList();
    } catch (e) {
      isError(true);
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> performAction(String action, int productId, int interestId, String remark) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      Map<String, dynamic> response;
      switch (action) {
        case 'approve':
          response = await BuyerServices.approveOffer(productId, interestId, remark);
          break;
        case 'confirm':
          response = await BuyerServices.confirmOffer(productId, interestId, remark);
          break;
        case 'reject_interest':
          response = await BuyerServices.rejectInterest(productId, interestId, remark);
          break;
        case 'reject_offer':
          response = await BuyerServices.rejectOffer(productId, interestId, remark);
          break;
        default:
          throw Exception("Unknown action");
      }
      
      Get.back(); // close loading dialog
      
      if (response['success'] == true) {
        Get.snackbar("Success", response['message'] ?? "Action successful", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchOffers(); // Refresh the list
      } else {
        Get.snackbar("Error", response['message'] ?? "Action failed", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
