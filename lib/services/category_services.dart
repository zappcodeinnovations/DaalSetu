import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/category/model/subcategory_model.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';

class CategoryService {
  /// ===============================
  /// FETCH CATEGORIES
  /// ===============================
  static Future<List<CategoryModel>> fetchCategories() async {
    try {
      final dynamic response = await ApiClient.get(
        endpoint: ApiUrls.categories,
        requireAuth: true,
      );

      if (response == null) {
        throw Exception("Invalid Categories response");
      }

      if (response is! List) {
        throw Exception("Expected List but got ${response.runtimeType}");
      }

      final List<CategoryModel> categories = [];

      for (var item in response) {
        categories.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
      }

      return categories;
    } catch (e, stack) {
      rethrow;
    }
  }

  /// ===============================
  /// FETCH SUBCATEGORIES
  /// ===============================
  static Future<List<SubCategoryModel>> fetchSubCategories() async {
    try {
      final dynamic response = await ApiClient.get(
        endpoint: ApiUrls.subcategories,
        requireAuth: true,
      );

      if (response == null) {
        throw Exception("Invalid SubCategories response");
      }

      if (response is! List) {
        throw Exception("Expected List but got ${response.runtimeType}");
      }

      final List<SubCategoryModel> subcategories = [];

      for (var item in response) {
        subcategories.add(
          SubCategoryModel.fromJson(Map<String, dynamic>.from(item)),
        );
      }

      return subcategories;
    } catch (e, stack) {
      rethrow;
    }
  }

  /// ===============================
  /// CREATE CATEGORY
  /// ===============================
  static Future<Map<String, dynamic>> createCategory(String name) async {
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.createCategory,
        body: {"category_name": name},
        requireAuth: true,
      );

      if (response == null || response is! Map<String, dynamic>) {
        throw Exception("Invalid response format");
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// ===============================
  /// FETCH CATEGORY BRANDS
  /// ===============================
  static Future<List<dynamic>> fetchCategoryBrands(int categoryId) async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.categoryBrands(categoryId),
        requireAuth: true,
      );

      if (response == null || response is! Map<String, dynamic>) {
        throw Exception("Invalid response format");
      }

      if (response['success'] == true) {
        return response['data'] ?? [];
      } else {
        throw Exception(response['message'] ?? "Failed to fetch brands");
      }
    } catch (e) {
      rethrow;
    }
  }
}
