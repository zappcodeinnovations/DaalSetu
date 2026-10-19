import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:get/get.dart';
import '../../../utils/app_snackbar.dart';

class AdminOffersController extends GetxController {
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  var offers = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      isLoading(true);
      hasError(false);
      List<ProductModel> products = [];
      try {
        products = await ProductService.getProducts();
      } catch (_) {}

      if (products.isEmpty) {
        try {
          final response = await ApiClient.get(
            endpoint: '/api/offers/list/',
            requireAuth: true,
            suppressErrorDialog: true,
          );
          final rawList = response is List
              ? response
              : (response is Map
                  ? (response['results'] ?? response['data'] ?? response['offers'] ?? [])
                  : []);
          if (rawList is List && rawList.isNotEmpty) {
            products = rawList
                .whereType<Map>()
                .map((m) => ProductModel.fromJson(Map<String, dynamic>.from(m)))
                .toList();
          }
        } catch (_) {}
      }

      offers.assignAll(products);
    } catch (e) {
      hasError(true);
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> toggleVisibility(int productId, bool currentValue) async {
    // Optimistic update
    final index = offers.indexWhere((o) => o.id == productId);
    if (index != -1) {
      final old = offers[index];
      offers[index] = old.copyWith(isActive: !currentValue);
      try {
        // Same endpoint the web "Active" switch uses.
        await SellerServices.toggleOfferStatus(productId, !currentValue);
      } catch (e) {
        offers[index] = old;
        AppSnackbar.snackbar("Error", e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> deleteOffer(int productId) async {
    try {
      await ProductService.deleteProduct(productId);
      offers.removeWhere((o) => o.id == productId);
      AppSnackbar.snackbar("Success", "Offer deleted successfully");
    } catch (e) {
      AppSnackbar.snackbar("Error", "Failed to delete offer");
    }
  }

  Future<void> manageStock(
    int productId, {
    required String action,
    required String quantity,
    required String bags,
    required String packingKg,
  }) async {
    // Validate: quantity ya bags mein se ek hona chahiye
    if (quantity.trim().isEmpty && bags.trim().isEmpty) {
      AppSnackbar.snackbar(
        'Validation Error',
        'Please enter Quantity or Bags to update stock.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await ProductService.updateStock(
        productId: productId,
        action: action,
        quantity: quantity.trim(),
        bags: bags.trim(),
        packingKg: packingKg.trim(),
      );

      AppSnackbar.snackbar(
        'Stock Updated ✅',
        'Stock $action action applied successfully.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh list to show updated stock
      await fetchOffers();
    } catch (e) {
      AppSnackbar.snackbar(
        'Error ❌',
        'Failed to update stock: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
