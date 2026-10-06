import '../model/category_dashboard_model.dart';
import '../model/seller_category_model.dart';
import '../../../../services/seller_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SellerCategoryController extends GetxController {
  var isLoading = true.obs;
  var dashboardData = Rxn<CategoryDashboardModel>();
  var categoryTree = <CategoryTreeModel>[].obs;
  var searchResults = <CategoryDetailModel>[].obs;
  var isSearching = false.obs;

  var brandsList = <BrandModel>[].obs;
  var selectedBrandIds = <int>[].obs;

  final searchController = TextEditingController();
  final categoryNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchAllData();
    fetchBrands();
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

  Future<void> fetchBrands() async {
    try {
      final data = await SellerServices.getBrandsDropdown();
      brandsList.assignAll(data.map((e) => BrandModel.fromJson(e)).toList());
    } catch (e) {
      print("Error fetching brands: $e");
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
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      isSearching(false);
      searchResults.clear();
      return;
    }

    isSearching(true);
    try {
      final data = await SellerServices.searchCategories(cleanQuery);
      if (data.isNotEmpty) {
        searchResults.assignAll(data.map((e) => CategoryDetailModel.fromJson(e)).toList());
        return;
      }
    } catch (e) {
      print("Search API Error, falling back to local search: $e");
    }

    // Local fallback: search inside categoryTree
    final List<CategoryDetailModel> localResults = [];
    void traverse(List<CategoryTreeModel> nodes) {
      for (final node in nodes) {
        if (node.name.toLowerCase().contains(cleanQuery)) {
          final isNodeActive = node.status.toLowerCase() == 'active';
          localResults.add(CategoryDetailModel(
            id: node.id,
            name: node.name,
            isActive: isNodeActive,
            level: node.level,
            brands: node.brands,
            path: node.name,
            status: node.status,
            childrenCount: node.children.length,
            fullPath: node.name,
            isRoot: node.level == 0,
            isLeaf: node.children.isEmpty,
            hasChildren: node.children.isNotEmpty,
          ));
        }
        if (node.children.isNotEmpty) {
          traverse(node.children);
        }
      }
    }
    traverse(categoryTree);
    searchResults.assignAll(localResults);
  }

  Future<void> addRootCategory() async {
    if (categoryNameController.text.isEmpty) return;
    try {
      isLoading(true);
      final body = {
        "category_name": categoryNameController.text.trim(),
        "is_active": "true",
        "brand_ids": selectedBrandIds.toList(),
      };
      await SellerServices.createCategory(body);
      categoryNameController.clear();
      selectedBrandIds.clear();
      Get.back();
      Get.snackbar("Success", "Category added successfully");
      fetchAllData();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
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

  void toggleBrandSelection(int brandId) {
    if (selectedBrandIds.contains(brandId)) {
      selectedBrandIds.remove(brandId);
    } else {
      selectedBrandIds.add(brandId);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    categoryNameController.dispose();
    super.onClose();
  }
}
