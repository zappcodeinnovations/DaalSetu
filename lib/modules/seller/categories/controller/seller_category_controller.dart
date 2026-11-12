import '../model/category_dashboard_model.dart';
import '../model/seller_category_model.dart';
import '../../../../services/seller_services.dart';
import '../../../../network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/app_snackbar.dart';

class SellerCategoryController extends GetxController {
  var isLoading = true.obs;
  var dashboardData = Rxn<CategoryDashboardModel>();
  var categoryTree = <CategoryTreeModel>[].obs;
  var searchResults = <CategoryDetailModel>[].obs;
  var isSearching = false.obs;

  var brandsList = <BrandModel>[].obs;
  var selectedBrandIds = <int>[].obs;
  var isBrandsLoading = false.obs;

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
      await Future.wait([fetchDashboard(), fetchTree()]);
      if (isSearching.value && searchController.text.trim().isNotEmpty) {
        await search(searchController.text);
      }
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchBrands() async {
    try {
      isBrandsLoading.value = true;
      final data = await SellerServices.getBrandsDropdown();
      brandsList.assignAll(data.map((e) => BrandModel.fromJson(e)).toList());
    } catch (e) {
      AppSnackbar.snackbar(
        "Could not load brands",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isBrandsLoading.value = false;
    }
  }

  Future<void> fetchDashboard() async {
    final data = await SellerServices.getCategoriesDashboard();
    dashboardData.value = CategoryDashboardModel.fromJson(data);
  }

  Future<void> fetchTree() async {
    final data = await SellerServices.getCategoriesTree();
    categoryTree.assignAll(
      data.map((e) => CategoryTreeModel.fromJson(e)).toList(),
    );
  }

  Future<void> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      isSearching(false);
      searchResults.clear();
      return;
    }

    isSearching(true);

    if (categoryTree.isEmpty && isLoading.value) {
      await fetchTree();
    }

    final List<CategoryDetailModel> localResults = [];
    void traverse(
      List<CategoryTreeModel> nodes, {
      String parentPath = '',
      String? parentName,
    }) {
      for (final node in nodes) {
        final currentPath = parentPath.isEmpty
            ? node.name
            : '$parentPath > ${node.name}';

        if (node.name.toLowerCase().contains(cleanQuery) ||
            currentPath.toLowerCase().contains(cleanQuery)) {
          final isNodeActive = node.status.toLowerCase() == 'active';
          localResults.add(
            CategoryDetailModel(
              id: node.id,
              name: node.name,
              parent: node.parentId,
              parentName: parentName,
              level: node.level,
              path: currentPath,
              isActive: isNodeActive,
              status: node.status,
              childrenCount: node.children.length,
              fullPath: currentPath,
              isRoot: node.level == 0 || node.parentId == null,
              isLeaf: node.children.isEmpty,
              imageUrl: node.image,
              hasChildren: node.children.isNotEmpty,
              brands: node.brands,
            ),
          );
        }

        if (node.children.isNotEmpty) {
          traverse(
            node.children,
            parentPath: currentPath,
            parentName: node.name,
          );
        }
      }
    }

    traverse(categoryTree);

    if (localResults.isEmpty && categoryTree.isEmpty) {
      try {
        final data = await SellerServices.searchCategories(cleanQuery);
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final name =
                (item['category_name'] ?? item['name'] ?? '').toString();
            if (name.toLowerCase().contains(cleanQuery)) {
              localResults.add(CategoryDetailModel.fromJson(item));
            }
          }
        }
      } catch (e) {
        debugPrint("API search fallback error: $e");
      }
    }

    searchResults.assignAll(localResults);
  }

  /// Seller-created categories wait for admin approval; say so instead of a plain "added".
  String _savedMessage(Map<String, dynamic> result, String label) {
    final data = result['data'] is Map ? result['data'] as Map : result;
    final pending = (data['status'] ?? '').toString().toLowerCase() == 'pending';
    return pending
        ? "$label sent for admin approval. It becomes active once approved."
        : "$label added successfully";
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
      final result = await SellerServices.createCategory(body);
      categoryNameController.clear();
      selectedBrandIds.clear();
      await fetchAllData();
      Get.back();
      AppSnackbar.snackbar("Success", _savedMessage(result, "Category"));
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> addSubCategory(int parentId) async {
    if (categoryNameController.text.isEmpty) return;
    try {
      isLoading(true);
      final result = await SellerServices.createSubCategory(
        parentId,
        categoryNameController.text.trim(),
      );
      categoryNameController.clear();
      await fetchAllData();
      Get.back();
      AppSnackbar.snackbar("Success", _savedMessage(result, "Sub-category"));
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateCategory(int id) async {
    if (categoryNameController.text.isEmpty) return;
    try {
      isLoading(true);
      await SellerServices.updateCategory(
        id,
        categoryNameController.text.trim(),
      );
      categoryNameController.clear();
      await fetchAllData();
      Get.back();
      AppSnackbar.snackbar("Success", "Category updated successfully");
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCategory(int id, {bool force = false}) async {
    try {
      isLoading(true);
      await SellerServices.deleteCategory(id, deleteSubcategories: force);
      AppSnackbar.snackbar("Success", "Category deleted successfully");
      fetchAllData();
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("has subcategories")) {
        _showForceDeleteConfirm(id);
      } else {
        AppSnackbar.snackbar("Error", errorMsg.replaceAll("Exception: ", ""));
      }
    } finally {
      isLoading(false);
    }
  }

  void _showForceDeleteConfirm(int id) {
    Get.defaultDialog(
      title: "Confirm Full Delete",
      middleText:
          "This category has sub-categories. Do you want to delete the full category tree?",
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
        AppSnackbar.snackbar("Success", "Image uploaded successfully");
        fetchAllData();
      } catch (e) {
        AppSnackbar.snackbar("Error", e.toString());
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
