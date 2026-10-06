import '../../../services/category_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/category_model.dart';

class CategoryController extends GetxController {

  var isLoading = false.obs;
  var allCategories = <CategoryModel>[].obs;
  var systemCategories = <CategoryModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    fetchCategories();
    super.onInit();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      // 1. Fetch system categories for approval picker
      try {
        final sysData = await CategoryService.fetchCategories();
        systemCategories.assignAll(sysData);
      } catch (_) {}

      // 2. Fetch buyer's approved/requested categories
      final data = await CategoryService.fetchBuyerCategories();
      allCategories.assignAll(data);
      _applyFilter();

    } catch (e) {
      Get.snackbar("Error", e.toString().replaceAll("Exception: ", ""));
    } finally {
      isLoading.value = false;
    }
  }

  void searchCategories(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (searchQuery.value.trim().isEmpty) {
      categories.assignAll(allCategories);
    } else {
      final q = searchQuery.value.trim().toLowerCase();
      categories.assignAll(
        allCategories.where((c) => c.categoryName.toLowerCase().contains(q)).toList(),
      );
    }
  }

  Future<bool> sendForApproval({List<int>? categoryIds, String? categoryName, String? note}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final response = await CategoryService.requestCategoryApproval(
        categoryIds: categoryIds ?? [],
        categoryName: categoryName,
        note: note,
      );
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "Success",
        response['message'] ?? "Category request sent for approval successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchCategories(); // Refresh list
      return true;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", ""),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> fetchCategoryBrands(int categoryId) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final brands = await CategoryService.fetchCategoryBrands(categoryId);
      Get.back(); // close dialog
      
      _showBrandsBottomSheet(brands);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showBrandsBottomSheet(List<dynamic> brands) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Category Brands",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (brands.isEmpty)
              const Center(child: Text("No brands found for this category."))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return ListTile(
                      leading: const Icon(Icons.branding_watermark, color: Colors.blue),
                      title: Text(brand['brand_name'] ?? 'Unknown'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
