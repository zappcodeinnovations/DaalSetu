import '../model/buyer_offer_model.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart';
import '../../../../services/product_services.dart';
import '../../../seller/products/model/product_media_model.dart';
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
        allOffersList
            .where(
              (o) =>
                  (o.displayTitle?.toLowerCase().contains(q) ?? false) ||
                  (o.displayQuantity?.toLowerCase().contains(q) ?? false) ||
                  (o.displayPrice?.toLowerCase().contains(q) ?? false) ||
                  (o.displayStatus?.toLowerCase().contains(q) ?? false),
            )
            .toList(),
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

      print(
        "📦 [BUYER OFFERS CONTROLLER] offerType: '$offerType' | fetched raw items count: ${data.length}",
      );
      final mapped = data
          .map((e) => BuyerOfferModel.fromJson(e))
          .where((offer) {
            // For public / active feeds ('today', 'all'), offers with visibility turned off
            // (isActive == false) must be excluded immediately.
            if (offerType == 'today' || offerType == 'all') {
              return offer.isActive;
            }
            return true;
          })
          .toList();
      allOffersList.assignAll(mapped);
      _applyFilter();
      _enrichMissingImages();
    } catch (e) {
      isError(true);
      final raw = e
          .toString()
          .replaceAll("Exception: ", "")
          .replaceAll("Error: ", "")
          .trim();
      errorMessage(
        raw.isNotEmpty ? raw : "Unable to load offers. Please try again.",
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _enrichMissingImages() async {
    try {
      final needsImage = allOffersList.where(
        (o) => (o.imageUrl == null || o.imageUrl!.trim().isEmpty),
      ).toList();
      if (needsImage.isEmpty) return;

      // 1. Fetch all product images from global /api/product-images/
      final images = await SellerServices.getProductImages();
      final Map<int, String> imageByProductId = {};
      for (final item in images) {
        if (item is Map) {
          final pId = ProductImageModel.parseProductId(Map<String, dynamic>.from(item));
          final url = item['image_url'] ?? item['image'] ?? item['file'] ?? item['download_url'];
          if (pId != null && url != null && url.toString().trim().isNotEmpty) {
            imageByProductId.putIfAbsent(pId, () => url.toString().trim());
          }
        }
      }

      bool updated = false;
      final updatedList = allOffersList.map((offer) {
        if (offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty) {
          return offer;
        }
        final pId = offer.productId ?? offer.id;
        if (pId != null && imageByProductId.containsKey(pId)) {
          updated = true;
          return offer.copyWith(imageUrl: imageByProductId[pId]);
        }
        return offer;
      }).toList();

      if (updated) {
        allOffersList.assignAll(updatedList);
        _applyFilter();
      }

      // 2. For remaining items without an image (e.g. up to first 10 items), fetch product detail
      final remaining = allOffersList.where(
        (o) => (o.imageUrl == null || o.imageUrl!.trim().isEmpty) && (o.productId != null || o.id != null),
      ).take(10).toList();

      for (final offer in remaining) {
        final pId = offer.productId ?? offer.id;
        if (pId != null && pId > 0) {
          try {
            final detail = await ProductService.getProductDetail(pId);
            if (detail.images.isNotEmpty) {
              final firstUrl = detail.images.first.imageUrl;
              if (firstUrl.trim().isNotEmpty) {
                final idx = allOffersList.indexWhere((o) => (o.productId ?? o.id) == pId);
                if (idx != -1) {
                  allOffersList[idx] = allOffersList[idx].copyWith(imageUrl: firstUrl);
                  _applyFilter();
                }
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
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
    print(
      "⭐ [BUYER SUBMIT INTEREST TRIGGERED] Product ID: $productId | Interest ID: $interestId | Amount: '$amount' | Qty: '$qty' | Date: '$deliveryDate' | To: '$loadingTo' | Condition: '$condition'",
    );
    if (productId <= 0) {
      AppSnackbar.showWarning(
        title: "Notice",
        message: "Invalid product reference",
      );
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

      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }

      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Interest submitted successfully",
      );
      fetchOffers();
      return true;
    } catch (e) {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      AppSnackbar.showError(title: "Error", message: msg.isNotEmpty ? msg : "Failed to submit interest.");
      return false;
    } finally {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    }
  }

  Future<bool> sendNegotiation(
    int productId,
    int interestId,
    String amount,
    String qty,
  ) async {
    print(
      "💬 [BUYER COUNTER TRIGGERED] Product ID: $productId | Interest ID: $interestId | Counter Amount: '$amount' | Counter Qty: '$qty'",
    );
    if (productId <= 0 || interestId <= 0) {
      AppSnackbar.showWarning(
        title: "Notice",
        message: "Invalid offer or interest reference",
      );
      return false;
    }

    bool dialogShown = false;
    try {
      Get.dialog(
        const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: false,
      );
      dialogShown = true;

      final res = await BuyerServices.sendNegotiationMessage(
        productId,
        interestId,
        counterAmount: amount.isNotEmpty ? amount : null,
        counterQuantity: qty.isNotEmpty ? qty : null,
      );

      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }

      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Counter proposal sent",
      );
      fetchOffers();
      return true;
    } catch (e) {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      AppSnackbar.showError(title: "Error", message: msg.isNotEmpty ? msg : "Failed to send negotiation.");
      return false;
    } finally {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    }
  }

  Future<bool> cancelInterest(int productId, int interestId) async {
    if (productId <= 0 || interestId <= 0) {
      AppSnackbar.showWarning(
        title: "Notice",
        message: "Invalid offer or interest reference.",
      );
      return false;
    }

    try {
      final response = await BuyerServices.cancelOfferInterest(
        productId,
        interestId,
      );
      AppSnackbar.showSuccess(
        title: "Success",
        message: response['message'] ?? "Interest cancelled successfully",
      );
      await fetchOffers();
      return true;
    } catch (e) {
      final message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Error: ', '')
          .trim();
      AppSnackbar.showError(
        title: "Error",
        message: message.isEmpty ? "Could not cancel interest" : message,
      );
      return false;
    }
  }

  Future<void> performAction(
    String action,
    int productId,
    int interestId,
    String remark,
  ) async {
    print(
      "🚀 [BUYER ACTION TRIGGERED] Action: $action | Product ID: $productId | Interest ID: $interestId | Remark: '$remark'",
    );
    if (productId <= 0 || interestId <= 0) {
      AppSnackbar.showWarning(
        title: "Notice",
        message:
            "Invalid offer or interest reference. Please refresh and try again.",
      );
      return;
    }

    bool dialogShown = false;
    try {
      Get.dialog(
        const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: false,
      );
      dialogShown = true;

      Map<String, dynamic> response;
      switch (action) {
        case 'confirm':
          response = await BuyerServices.confirmOffer(
            productId,
            interestId,
            remark,
          );
          break;
        case 'reject_interest':
          response = await BuyerServices.rejectInterest(
            productId,
            interestId,
            remark,
          );
          break;
        case 'approve':
          response = await BuyerServices.approveOffer(
            productId,
            interestId,
            remark,
          );
          break;
        case 'reject_offer':
          response = await BuyerServices.rejectOffer(
            productId,
            interestId,
            remark,
          );
          break;
        default:
          throw Exception("Unknown action");
      }

      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
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
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      AppSnackbar.showError(
        title: "Error",
        message: msg.isNotEmpty ? msg : "Action failed. Please try again.",
      );
    } finally {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    }
  }
}
