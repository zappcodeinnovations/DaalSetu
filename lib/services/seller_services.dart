import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';
import 'package:http/http.dart';

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
  static Future<List<dynamic>> getCompanies() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.company,
      requireAuth: true,
    );
    
    if (response == null) {
      throw Exception("Failed to fetch companies");
    }

    // Assuming the API returns a list directly or wrapped in data
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic> && response.containsKey("data")) {
      return response["data"];
    } else {
      return [response];
    }
  }

  /// ============================================================
  /// CREATE COMPANY
  /// ============================================================
  static Future<Map<String, dynamic>> createCompany(Map<String, dynamic> data) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.company,
      body: data,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    
    return response;
  }

  /// ============================================================
  /// EDIT COMPANY
  /// ============================================================
  static Future<Map<String, dynamic>> editCompany(Map<String, dynamic> data) async {
    final response = await ApiClient.patch( // Or Patch depending on API definition
      endpoint: ApiUrls.company,
      data: data,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    
    return response;
  }

  /// ============================================================
  /// GET COMPANY DROPDOWN
  /// ============================================================
  static Future<List<dynamic>> getCompanyDropdown() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.companyDropdown,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["data"];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch company dropdown");
    }
  }

  /// ============================================================
  /// GET PRIMARY COMPANY
  /// ============================================================
  static Future<Map<String, dynamic>> getPrimaryCompany() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.companyPrimary,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["data"];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch primary company");
    }
  }

  /// ============================================================
  /// SET PRIMARY COMPANY
  /// ============================================================
  static Future<String> setPrimaryCompany(String id) async {
    final response = await ApiClient.post(
      endpoint: "/api/company/$id/set-primary/",
      body: {},
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["message"] ?? "Success";
    } else {
      throw Exception(response["message"] ?? "Failed to set primary company");
    }
  }

  /// ============================================================
  /// GET COMPANY BY ID
  /// ============================================================
  static Future<Map<String, dynamic>> getCompanyById(String id) async {
    final response = await ApiClient.get(
      endpoint: "/api/company/$id/",
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
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
