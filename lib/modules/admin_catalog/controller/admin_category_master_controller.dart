import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';

class CategoryTreeModel {
  final int id;
  final String name;
  final int level;
  final int? parentId;
  final String? image;
  final String status;
  final List<CategoryTreeModel> children;
  final List<Map<String, dynamic>> brands;

  CategoryTreeModel({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
    this.image,
    required this.status,
    required this.children,
    required this.brands,
  });

  factory CategoryTreeModel.fromJson(Map<String, dynamic> json) {
    return CategoryTreeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      level: json['level'] as int,
      parentId: json['parent_id'] as int?,
      image: json['image'] as String?,
      status: json['status'] as String? ?? 'active',
      children: (json['children'] as List? ?? [])
          .map((c) => CategoryTreeModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      brands: List<Map<String, dynamic>>.from(json['brands'] ?? []),
    );
  }
}

class AdminCategoryMasterController extends GetxController {
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  
  // Data
  var treeCategories = <CategoryTreeModel>[].obs;
  var rootCategories = <CategoryTreeModel>[].obs;
  var allBrands = <Map<String, dynamic>>[].obs;
  
  // Stats
  var totalCount = 0.obs;
  var rootCount = 0.obs;
  var subCount = 0.obs;
  var activeCount = 0.obs;
  var inactiveCount = 0.obs;

  // Search & Filter State
  var searchQuery = ''.obs;
  var filterLevel = Rxn<int>();
  var filterStatus = Rxn<String>();
  var filterHasImage = Rxn<bool>();
  var brandSearchQuery = ''.obs;

  // Form State
  final nameCtrl = TextEditingController();
  var selectedParentId = Rxn<int>();
  var selectedStatus = 'active'.obs;
  var selectedBrandIds = <int>[].obs;
  var selectedImagePath = RxnString();
  var editingCategoryId = Rxn<int>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading(true);
    try {
      await Future.wait([
        _fetchCategoriesTree(),
        _fetchBrands(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load data: $e', 
        backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
    } finally {
      isLoading(false);
    }
  }

  Future<void> _fetchCategoriesTree() async {
    final dynamic response = await ApiClient.get(
      endpoint: '/api/categories/tree/',
      requireAuth: true,
    );

    if (response is Map && response['success'] == true) {
      final list = (response['data'] as List)
          .map((item) => CategoryTreeModel.fromJson(item))
          .toList();
      
      treeCategories.assignAll(list);
      rootCategories.assignAll(list.where((c) => c.level == 0));
      
      // Calculate Stats
      int total = 0;
      int active = 0;
      int inactive = 0;
      int root = rootCategories.length;
      int sub = 0;
      
      void countNodes(List<CategoryTreeModel> nodes) {
        for (var node in nodes) {
          total++;
          if (node.level > 0) sub++;
          if (node.status.toLowerCase() == 'active') {
            active++;
          } else {
            inactive++;
          }
          countNodes(node.children);
        }
      }
      countNodes(list);
      
      totalCount.value = total;
      rootCount.value = root;
      subCount.value = sub;
      activeCount.value = active;
      inactiveCount.value = inactive;
    }
  }

  Future<void> _fetchBrands() async {
    final dynamic response = await ApiClient.get(
      endpoint: '/api/brands/',
      requireAuth: true,
    );

    if (response is Map && response['success'] == true) {
      final dataList = response['data'] as List? ?? [];
      allBrands.assignAll(dataList.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    }
  }

  List<Map<String, dynamic>> get filteredBrands {
    if (brandSearchQuery.isEmpty) return allBrands;
    final q = brandSearchQuery.value.toLowerCase();
    return allBrands.where((b) {
      final name = (b['brand_name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  void selectAllBrands() {
    selectedBrandIds.assignAll(filteredBrands.map((b) => b['id'] as int).toList());
  }

  void deselectAllBrands() {
    final filteredIds = filteredBrands.map((b) => b['id'] as int).toSet();
    selectedBrandIds.removeWhere((id) => filteredIds.contains(id));
  }

  // Local Filtering Logic
  List<CategoryTreeModel> get filteredTree {
    if (searchQuery.isEmpty && filterLevel.value == null && filterStatus.value == null && filterHasImage.value == null) {
      return treeCategories;
    }

    List<CategoryTreeModel> filterNodes(List<CategoryTreeModel> nodes) {
      List<CategoryTreeModel> result = [];
      for (var node in nodes) {
        // Recursively filter children
        final filteredChildren = filterNodes(node.children);

        // Check if node matches criteria
        bool matches = true;
        
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.value.toLowerCase();
          bool matchesName = node.name.toLowerCase().contains(q);
          bool matchesBrand = node.brands.any((b) => (b['brand_name'] ?? '').toString().toLowerCase().contains(q));
          if (!matchesName && !matchesBrand) matches = false;
        }
        
        if (filterLevel.value != null && node.level != filterLevel.value) {
          matches = false;
        }

        if (filterStatus.value != null && filterStatus.value != 'All' && node.status.toLowerCase() != filterStatus.value!.toLowerCase()) {
          matches = false;
        }

        if (filterHasImage.value != null) {
          if (filterHasImage.value == true && node.image == null) matches = false;
          if (filterHasImage.value == false && node.image != null) matches = false;
        }

        // Keep node if it matches OR if any of its children match
        if (matches || filteredChildren.isNotEmpty) {
          result.add(CategoryTreeModel(
            id: node.id,
            name: node.name,
            level: node.level,
            parentId: node.parentId,
            image: node.image,
            status: node.status,
            children: filteredChildren, // Only show matched children
            brands: node.brands,
          ));
        }
      }
      return result;
    }

    return filterNodes(treeCategories);
  }

  void toggleBrandSelection(int brandId) {
    if (selectedBrandIds.contains(brandId)) {
      selectedBrandIds.remove(brandId);
    } else {
      selectedBrandIds.add(brandId);
    }
  }

  void clearFilters() {
    searchQuery.value = '';
    filterLevel.value = null;
    filterStatus.value = null;
    filterHasImage.value = null;
  }

  void openForm({CategoryTreeModel? category, int? defaultParentId}) {
    if (category != null) {
      // Edit Mode
      editingCategoryId.value = category.id;
      nameCtrl.text = category.name;
      selectedParentId.value = category.parentId;
      selectedStatus.value = category.status;
      selectedBrandIds.assignAll(category.brands.map((b) => b['id'] as int).toList());
      selectedImagePath.value = null; // Don't pre-fill path as it requires re-upload if changed
    } else {
      // Add Mode
      editingCategoryId.value = null;
      nameCtrl.clear();
      selectedParentId.value = defaultParentId;
      selectedStatus.value = 'active';
      selectedBrandIds.clear();
      selectedImagePath.value = null;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final response = await ApiClient.delete(
        endpoint: '/api/categories/$id/',
        requireAuth: true,
      );
      if (response['success'] == true) {
        Get.snackbar('Success', 'Category deleted successfully.', backgroundColor: Colors.green.shade100);
        await _fetchCategoriesTree();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category: $e', backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> submitCategory() async {
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Category Name is required.', backgroundColor: Colors.orange.shade100);
      return;
    }

    isSubmitting(true);
    try {
      final body = {
        'category_name': nameCtrl.text.trim(),
        'is_active': selectedStatus.value.toLowerCase() == 'active',
        if (selectedParentId.value != null) 'parent': selectedParentId.value,
        // brands are omitted because the endpoint does not support them in POST/PATCH directly
      };

      int categoryId;

      if (editingCategoryId.value != null) {
        // Update
        final response = await ApiClient.patch(
          endpoint: '/api/categories/${editingCategoryId.value}/',
          data: body,
          requireAuth: true,
        );
        categoryId = editingCategoryId.value!;
        Get.snackbar('Success', 'Category updated successfully.', backgroundColor: Colors.green.shade100);
      } else {
        // Create
        final response = await ApiClient.post(
          endpoint: '/api/categories/',
          body: body,
          requireAuth: true,
        );
        categoryId = response['data']['id'] ?? response['id'];
        Get.snackbar('Success', 'Category added successfully.', backgroundColor: Colors.green.shade100);
      }

      // Upload image if selected
      if (selectedImagePath.value != null && selectedImagePath.value!.isNotEmpty) {
        try {
          await ApiClient.postMultipart(
            endpoint: '/api/categories/$categoryId/image/',
            fields: {},
            files: {'image': selectedImagePath.value!},
            requireAuth: true,
          );
        } catch (imgErr) {
          Get.snackbar('Warning', 'Category saved but image upload failed: $imgErr', backgroundColor: Colors.orange.shade100);
        }
      }

      await _fetchCategoriesTree();
      Get.back(); // Close form bottom sheet
    } catch (e) {
      Get.snackbar('Error', 'Failed to save category: $e', backgroundColor: Colors.red.shade100);
    } finally {
      isSubmitting(false);
    }
  }
}
