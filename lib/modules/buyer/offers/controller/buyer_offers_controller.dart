import '../model/buyer_offer_model.dart';
import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
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

      print("📦 [BUYER OFFERS CONTROLLER] offerType: '$offerType' | fetched raw items count: ${data.length}");
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

  Future<bool> submitInterest(
    int productId,
    String amount,
    String qty,
    String remark, {
    String? deliveryDate,
    String? loadingTo,
    String? condition,
    int? interestId,
  }) async {
    print("⭐ [BUYER SUBMIT INTEREST TRIGGERED] Product ID: $productId | Interest ID: $interestId | Amount: '$amount' | Qty: '$qty' | Date: '$deliveryDate' | To: '$loadingTo' | Condition: '$condition'");
    if (productId <= 0) {
      AppSnackbar.showWarning(title: "Notice", message: "Invalid product reference");
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
        deliveryDate: deliveryDate,
        loadingTo: loadingTo,
        condition: condition,
        interestId: interestId,
        remark: remark,
      );

      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }

      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Interest submitted successfully",
      );
      fetchOffers();
      return true;
    } catch (e) {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
      );
      return false;
    } finally {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }

  Future<bool> sendNegotiation(int productId, int interestId, String amount, String qty) async {
    print("💬 [BUYER COUNTER TRIGGERED] Product ID: $productId | Interest ID: $interestId | Counter Amount: '$amount' | Counter Qty: '$qty'");
    if (productId <= 0 || interestId <= 0) {
      AppSnackbar.showWarning(title: "Notice", message: "Invalid offer or interest reference");
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
        counterAmount: amount.isNotEmpty ? amount : null,
        counterQuantity: qty.isNotEmpty ? qty : null,
      );

      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }

      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Counter proposal sent",
      );
      fetchOffers();
      return true;
    } catch (e) {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
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
      AppSnackbar.showWarning(title: "Notice", message: "Invalid offer or interest reference. Please refresh and try again.");
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
        AppSnackbar.showSuccess(
          title: "Success",
          message: response['message'] ?? "Action successful",
        );
        fetchOffers(); // Refresh the list
      } else {
        AppSnackbar.showError(
          title: "Error",
          message: response['message'] ?? "Action failed",
        );
      }
    } catch (e) {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
        dialogShown = false;
      }
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
      );
    } finally {
      if (dialogShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
    }
  }
}
