import 'package:daalsetu/services/category_services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/category_model.dart';

class CategoryController extends GetxController {

  var isLoading = false.obs;
  var categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    fetchCategories();
    super.onInit();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final data = await CategoryService.fetchCategories();
      categories.assignAll(data);

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createCategory(String name) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final response = await CategoryService.createCategory(name);
      Get.back(); // close dialog
      
      if (response['success'] == true || response['category_name'] == name) {
        Get.snackbar("Success", "Category created successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        fetchCategories(); // Refresh list
      } else {
        Get.snackbar("Error", response['message'] ?? "Failed to create category", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
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
