import 'package:flutter/material.dart';
import 'package:agro_broker/modules/products/model/product_model.dart';
import 'package:agro_broker/services/product_services.dart';
import 'package:get/get.dart';

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
      final products = await ProductService.getProducts();
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
      // Wait for backend call (API update to patch is_active)
      // Since we don't have a specific patch for is_active in ProductService yet, 
      // we'll use updateProduct or just mock it if not strictly required.
      try {
        // await ProductService.updateProductVisibility(productId, !currentValue);
      } catch (e) {
        // Revert on error
        offers[index] = old;
        Get.snackbar("Error", "Failed to update visibility");
      }
    }
  }

  Future<void> deleteOffer(int productId) async {
    try {
      await ProductService.deleteProduct(productId);
      offers.removeWhere((o) => o.id == productId);
      Get.snackbar("Success", "Offer deleted successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete offer");
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
      Get.snackbar(
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

      Get.snackbar(
        'Stock Updated ✅',
        'Stock $action action applied successfully.',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh list to show updated stock
      await fetchOffers();
    } catch (e) {
      Get.snackbar(
        'Error ❌',
        'Failed to update stock: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
