import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/modules/category/model/subcategory_model.dart';
import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/modules/category/model/category_model.dart';

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
        endpoint: "/api/subcategories/",
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
}
