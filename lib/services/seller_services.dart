import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/modules/seller/company/model/seller_company_model.dart';

class SellerServices {
  /// ============================================================
  /// GET SELLER DASHBOARD
  /// ============================================================
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.sellerDashboard,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["data"];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch dashboard data");
    }
  }

  /// ============================================================
  /// GET COMPANY LIST
  /// ============================================================
  static Future<List<SellerCompanyModel>> getCompanies() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.company,
      requireAuth: true,
    );
    
    if (response == null) {
      throw Exception("Failed to fetch companies");
    }

    if (response is List) {
      return response.map((e) => SellerCompanyModel.fromJson(e)).toList();
    } else if (response is Map<String, dynamic> && response.containsKey("data")) {
      return (response["data"] as List).map((e) => SellerCompanyModel.fromJson(e)).toList();
    } else {
       return [SellerCompanyModel.fromJson(response)];
    }
  }

  /// ============================================================
  /// CREATE COMPANY
  /// ============================================================
  static Future<SellerCompanyModel> createCompany(Map<String, dynamic> data) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.company,
      body: data,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    
    return SellerCompanyModel.fromJson(response);
  }

  /// ============================================================
  /// UPDATE COMPANY (PUT)
  /// ============================================================
  static Future<SellerCompanyModel> updateCompany(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.put(
      endpoint: "/api/company/$id/",
      data: data,
      requireAuth: true,
    );
    return SellerCompanyModel.fromJson(response);
  }

  /// ============================================================
  /// SET PRIMARY COMPANY (POST)
  /// ============================================================
  static Future<void> setPrimaryCompany(int id) async {
    await ApiClient.post(
      endpoint: "/api/company/$id/set-primary/",
      body: {},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// GET COMPANY BY ID
  /// ============================================================
  static Future<SellerCompanyModel> getCompanyById(int id) async {
    final response = await ApiClient.get(
      endpoint: "/api/company/$id/",
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return SellerCompanyModel.fromJson(response);
  }


  /// ============================================================
  /// CATEGORIES DASHBOARD
  /// ============================================================
  static Future<Map<String, dynamic>> getCategoriesDashboard() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.categoriesDashboard,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["data"];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch categories dashboard");
    }
  }

  /// ============================================================
  /// CATEGORIES TREE
  /// ============================================================
  static Future<List<dynamic>> getCategoriesTree() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.categoriesTree,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["data"];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch categories tree");
    }
  }

  /// ============================================================
  /// CREATE CATEGORY
  /// ============================================================
  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.categories,
      body: data,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    
    return response;
  }

  /// ============================================================
  /// SEARCH CATEGORY
  /// ============================================================
  static Future<List<dynamic>> searchCategory(String query) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.categories}?search=$query",
      requireAuth: true,
    );

    if (response == null) {
      throw Exception("Failed to search categories");
    }
    
    if (response is List) {
      return response;
    } else {
      return [];
    }
  }
}
