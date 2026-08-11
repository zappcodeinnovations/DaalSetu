import 'package:daalsetu/modules/seller/categories/model/category_dashboard_model.dart';
import 'package:daalsetu/modules/seller/categories/model/seller_category_model.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SellerCategoryController extends GetxController {
  var isLoading = true.obs;
  var dashboardData = Rxn<CategoryDashboardModel>();
  var categoryTree = <CategoryTreeModel>[].obs;
  var searchResults = <CategoryDetailModel>[].obs;
  var isSearching = false.obs;

  final searchController = TextEditingController();
  final categoryNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      isLoading(true);
      await Future.wait([
        fetchDashboard(),
        fetchTree(),
      ]);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchDashboard() async {
    final data = await SellerServices.getCategoriesDashboard();
    dashboardData.value = CategoryDashboardModel.fromJson(data);
  }

  Future<void> fetchTree() async {
    final data = await SellerServices.getCategoriesTree();
    categoryTree.assignAll(data.map((e) => CategoryTreeModel.fromJson(e)).toList());
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      isSearching(false);
      searchResults.clear();
      return;
    }

    try {
      isSearching(true);
      final data = await SellerServices.searchCategories(query);
      searchResults.assignAll(data.map((e) => CategoryDetailModel.fromJson(e)).toList());
    } catch (e) {
      print("Search Error: $e");
    }
  }

  Future<void> addSubCategory(int parentId) async {
    if (categoryNameController.text.isEmpty) return;
    try {
      isLoading(true);
      await SellerServices.createSubCategory(parentId, categoryNameController.text.trim());
      categoryNameController.clear();
      Get.back();
      Get.snackbar("Success", "Sub-category added successfully");
      fetchAllData();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateCategory(int id) async {
    if (categoryNameController.text.isEmpty) return;
    try {
      isLoading(true);
      await SellerServices.updateCategory(id, categoryNameController.text.trim());
      categoryNameController.clear();
      Get.back();
      Get.snackbar("Success", "Category updated successfully");
      fetchAllData();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCategory(int id, {bool force = false}) async {
    try {
      isLoading(true);
      await SellerServices.deleteCategory(id, deleteSubcategories: force);
      Get.snackbar("Success", "Category deleted successfully");
      fetchAllData();
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("has subcategories")) {
        _showForceDeleteConfirm(id);
      } else {
        Get.snackbar("Error", errorMsg.replaceAll("Exception: ", ""));
      }
    } finally {
      isLoading(false);
    }
  }

  void _showForceDeleteConfirm(int id) {
    Get.defaultDialog(
      title: "Confirm Full Delete",
      middleText: "This category has sub-categories. Do you want to delete the full category tree?",
      textConfirm: "DELETE ALL",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        deleteCategory(id, force: true);
      },
      textCancel: "CANCEL",
    );
  }

  Future<void> uploadImage(int id) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        isLoading(true);
        await SellerServices.uploadCategoryImage(id, image.path);
        Get.snackbar("Success", "Image uploaded successfully");
        fetchAllData();
      } catch (e) {
        Get.snackbar("Error", e.toString());
      } finally {
        isLoading(false);
      }
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    categoryNameController.dispose();
    super.onClose();
  }
}
