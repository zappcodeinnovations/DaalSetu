import '../model/buyer_offer_model.dart';
import '../../../../services/buyer_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BuyerOffersController extends GetxController {
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;

  var offersList = <BuyerOfferModel>[].obs;
  var allOffersList = <BuyerOfferModel>[].obs;
  var searchQuery = ''.obs;

  // The type of offers to fetch (e.g., 'all', 'today', 'pending', 'previous', 'interests')
  final String offerType;

  BuyerOffersController({required this.offerType});

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  void searchOffers(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (searchQuery.value.trim().isEmpty) {
      offersList.assignAll(allOffersList);
    } else {
      final q = searchQuery.value.trim().toLowerCase();
      offersList.assignAll(
        allOffersList.where((o) =>
          (o.displayTitle?.toLowerCase().contains(q) ?? false) ||
          (o.displayQuantity?.toLowerCase().contains(q) ?? false) ||
          (o.displayPrice?.toLowerCase().contains(q) ?? false) ||
          (o.displayStatus?.toLowerCase().contains(q) ?? false)
        ).toList(),
      );
    }
  }

  Future<void> fetchOffers() async {
    try {
      isLoading(true);
      isError(false);

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
        case 'requirements':
          data = await BuyerServices.getOffers();
          break;
        case 'all':
        default:
          data = await BuyerServices.getAllOffers();
          break;
      }

      final mapped = data.map((e) => BuyerOfferModel.fromJson(e)).toList();
      allOffersList.assignAll(mapped);
      _applyFilter();
    } catch (e) {
      isError(true);
      final raw = e.toString().replaceAll("Exception: ", "").replaceAll("Error: ", "").trim();
      errorMessage(raw.isNotEmpty ? raw : "Unable to load offers. Please try again.");
    } finally {
      isLoading(false);
    }
  }

  Future<bool> submitInterest(int productId, String amount, String qty, String remark) async {
    print("⭐ [BUYER SUBMIT INTEREST TRIGGERED] Product ID: $productId | Amount: '$amount' | Qty: '$qty' | Remark: '$remark'");
    if (productId <= 0) {
      Get.snackbar("Notice", "Invalid product reference", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }

    bool dialogShown = false;
    try {
      Get.dialog(
        const PopScope(
          canPop: true,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: true,
      );
      dialogShown = true;

      final res = await BuyerServices.showInterest(
        productId,
        requestedAmount: amount,
        requestedQuantity: qty,
        remark: remark,
      );

      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }

      Get.snackbar(
        "Success",
        res['message'] ?? "Interest submitted successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchOffers();
      return true;
    } catch (e) {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", "").replaceAll("Error: ", "").trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }

  Future<bool> sendNegotiation(int productId, int interestId, String message, String amount, String qty) async {
    print("💬 [BUYER NEGOTIATION TRIGGERED] Product ID: $productId | Interest ID: $interestId | Message: '$message' | Counter Amount: '$amount' | Counter Qty: '$qty'");
    if (productId <= 0 || interestId <= 0) {
      Get.snackbar("Notice", "Invalid offer or interest reference", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return false;
    }

    bool dialogShown = false;
    try {
      Get.dialog(
        const PopScope(
          canPop: true,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: true,
      );
      dialogShown = true;

      final res = await BuyerServices.sendNegotiationMessage(
        productId,
        interestId,
        message: message,
        counterAmount: amount.isNotEmpty ? amount : null,
        counterQuantity: qty.isNotEmpty ? qty : null,
      );

      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }

      Get.snackbar(
        "Success",
        res['message'] ?? "Message / counter offer sent",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchOffers();
      return true;
    } catch (e) {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", "").replaceAll("Error: ", "").trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }

  Future<void> performAction(String action, int productId, int interestId, String remark) async {
    print("🚀 [BUYER ACTION TRIGGERED] Action: $action | Product ID: $productId | Interest ID: $interestId | Remark: '$remark'");
    if (productId <= 0 || interestId <= 0) {
      Get.snackbar("Notice", "Invalid offer or interest reference. Please refresh and try again.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    bool dialogShown = false;
    try {
      Get.dialog(
        const PopScope(
          canPop: true,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: true,
      );
      dialogShown = true;

      Map<String, dynamic> response;
      switch (action) {
        case 'confirm':
          response = await BuyerServices.confirmOffer(productId, interestId, remark);
          break;
        case 'reject_interest':
          response = await BuyerServices.rejectInterest(productId, interestId, remark);
          break;
        case 'approve':
          response = await BuyerServices.approveOffer(productId, interestId, remark);
          break;
        case 'reject_offer':
          response = await BuyerServices.rejectOffer(productId, interestId, remark);
          break;
        default:
          throw Exception("Unknown action");
      }
      
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      
      if (response['success'] == true || response['message'] != null) {
        Get.snackbar(
          "Success",
          response['message'] ?? "Action successful",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchOffers(); // Refresh the list
      } else {
        Get.snackbar(
          "Error",
          response['message'] ?? "Action failed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", "").replaceAll("Error: ", "").trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }
}
