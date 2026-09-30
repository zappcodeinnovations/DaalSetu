import 'package:agro_broker/modules/category/model/category_model.dart';
import 'package:agro_broker/services/category_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:agro_broker/services/product_services.dart';
import '../model/product_model.dart';

class ProductController extends GetxController {
  /// ===============================
  /// STATE VARIABLES
  /// ===============================
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final processingProductId = RxnInt();

  final products = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;

  final errorMessage = "".obs;

  /// ===============================
  /// INIT
  /// ===============================
  @override
  void onInit() {
    fetchProducts();
    super.onInit();
  }

  /// ===============================
  /// FETCH PRODUCTS
  /// ===============================
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      debugPrint("🚀 Fetching Products...");

      final data = await ProductService.getProducts();

      debugPrint("📦 PRODUCT COUNT: ${data.length}");

      products.assignAll(data);

      if (products.isEmpty) {
        debugPrint("⚠️ No products received from API");
      }
    } catch (e) {
      debugPrint("❌ PRODUCT FETCH ERROR: $e");

      errorMessage.value = e.toString();

      Get.snackbar(
        "Error",
        "Failed to load products",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final data = await CategoryService.fetchCategories();

      categories.assignAll(data);

      debugPrint("Loaded Categories: ${categories.length}");
    } catch (e) {
      debugPrint("Category error: $e");
    }
  }

  /// ===============================
  /// REFRESH PRODUCTS
  /// ===============================
  Future<void> refreshProducts() async {
    try {
      isRefreshing.value = true;

      debugPrint("🔄 Refreshing products...");

      final data = await ProductService.getProducts();

      products.assignAll(data);

      debugPrint("✅ Products refreshed");
    } catch (e) {
      debugPrint("❌ REFRESH ERROR: $e");

      Get.snackbar(
        "Error",
        "Failed to refresh products",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// ===============================
  /// CREATE PRODUCT
  /// ===============================
  Future<void> createProduct({
    required String title,
    required String amount,
    required String location,
    required String categoryId,
    String? sellerId,
    String? imagePath,
  }) async {
    try {
      isLoading.value = true;

      final productResponse = await ProductService.createProduct(
        title: title,
        baseAmount: amount,
        loadingLocation: location,
        categoryId: categoryId,
        sellerId: sellerId,
      );

      final productId = productResponse["id"];

      /// Upload image if selected
      if (imagePath != null) {
        await ProductService.uploadProductImage(
          productId: productId,
          imagePath: imagePath,
          isPrimary: true,
        );
      }

      Get.snackbar("Success", "Product created");

      await fetchProducts();

      Get.back();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct({
    required ProductModel product,
    required String title,
    required String description,
    required String amount,
    required String location,
  }) async {
    try {
      processingProductId.value = product.id;
      final updated = await ProductService.updateProduct(
        productId: product.id,
        title: title,
        description: description,
        amount: amount,
        loadingLocation: location,
        categoryId: product.category?.id,
      );
      final index = products.indexWhere((item) => item.id == product.id);
      if (index >= 0) products[index] = updated;
      Get.snackbar(
        "Product updated",
        "$title was updated successfully.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Update failed",
        "Could not update this product. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      processingProductId.value = null;
    }
  }

  Future<bool> deleteProduct(ProductModel product) async {
    try {
      processingProductId.value = product.id;
      await ProductService.deleteProduct(product.id);
      products.removeWhere((item) => item.id == product.id);
      Get.snackbar(
        "Product deleted",
        "${product.title} was removed.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Delete failed",
        "Could not delete this product. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    } finally {
      processingProductId.value = null;
    }
  }

  /// ===============================
  /// CLEAR PRODUCTS
  /// ===============================
  void clearProducts() {
    products.clear();
  }
}
