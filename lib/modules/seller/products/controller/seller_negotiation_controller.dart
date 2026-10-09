import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/offer_interest_model.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

class SellerNegotiationController extends GetxController {
  final int productId;
  SellerNegotiationController({required this.productId});

  var isLoading = true.obs;
  var interestsList = <OfferInterestModel>[].obs;
  var productData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchInterests();
  }

  Future<void> fetchInterests() async {
    try {
      isLoading(true);
      final response = await SellerServices.getOfferInterests(productId);
      if (response['success'] == true) {
        if (response['product'] is Map<String, dynamic>) {
          productData.value = response['product'];
        }
        final list = (response['interests'] as List?) ?? [];
        interestsList.value = list
            .map((e) => OfferInterestModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not fetch offer interests: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> sendCounterOffer({
    required int interestId,
    required String counterPrice,
    required String counterQuantity,
    int? counterBagCount,
    String? counterPackingWeightKg,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.sendCounterOfferMessage(
        productId,
        interestId,
        counterPrice: counterPrice,
        counterQuantity: counterQuantity,
        counterBagCount: counterBagCount,
        counterPackingWeightKg: counterPackingWeightKg,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      if (res['success'] == true) {
        Get.snackbar(
          "Success",
          res['message'] ?? "Counter offer sent",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchInterests();
      } else {
        Get.snackbar(
          "Error",
          res['message'] ?? "Failed to send counter offer",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Seller accepts the buyer's interest (interested -> seller_confirmed); admin confirms the deal later.
  Future<void> approveInterest(int interestId) async {
    final confirmed = await SellerUi.confirm(
      'Accept buyer interest?',
      'This will send the buyer interest for the next confirmation step.',
      confirmText: 'Accept',
      color: Colors.green,
    );
    if (!confirmed) return;
    final result = await SellerUi.run(
      () => SellerServices.approveBuyerInterest(productId, interestId),
    );
    if (result != null) fetchInterests();
  }

  Future<void> rejectInterest(int interestId) async {
    final confirmed = await SellerUi.confirm(
      'Reject buyer interest?',
      'This action cannot be undone.',
      confirmText: 'Reject',
      color: Colors.red,
    );
    if (!confirmed) return;
    final result = await SellerUi.run(
      () => SellerServices.rejectBuyerInterest(productId, interestId),
    );
    if (result != null) fetchInterests();
  }

  Future<void> confirmDeal(int interestId, {String? adminRemark}) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.confirmOfferDeal(
        productId,
        interestId,
        adminRemark: adminRemark,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      if (res['success'] == true) {
        Get.snackbar(
          "Deal Confirmed",
          res['message'] ?? "Deal confirmed successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchInterests();
      } else {
        Get.snackbar(
          "Error",
          res['message'] ?? "Failed to confirm deal",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
