import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/modules/seller/company/model/seller_company_model.dart';

class SellerServices {
  /// ============================================================
  /// GET BRANDS DROPDOWN
  /// ============================================================
  static Future<List<dynamic>> getBrandsDropdown() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.brandsDropdown,
      requireAuth: true,
    );

    if (response == null) {
      throw Exception("Failed to fetch brands");
    }

    if (response is Map<String, dynamic> && response["success"] == true) {
      return response["data"] is List ? response["data"] : [];
    }
    return [];
  }

  /// ============================================================
  /// CREATE CATEGORY (ROOT)
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
      endpoint: ApiUrls.companyDetails(id),
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
      endpoint: ApiUrls.setPrimaryCompany(id),
      body: {},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// GET COMPANY BY ID
  /// ============================================================
  static Future<SellerCompanyModel> getCompanyById(int id) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.companyDetails(id),
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
  /// CATEGORIES TREE (GET)
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
  /// GET CATEGORY BY ID
  /// ============================================================
  static Future<Map<String, dynamic>> getCategoryById(int id) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.categoryDetails(id),
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// SEARCH CATEGORIES
  /// ============================================================
  static Future<List<dynamic>> searchCategories(String query) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.categories}?search=$query",
      requireAuth: true,
    );

    if (response == null) {
      throw Exception("Failed to search categories");
    }

    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic> && response.containsKey("data")) {
      return response["data"];
    }
    return [];
  }

  /// ============================================================
  /// CREATE SUB CATEGORY
  /// ============================================================
  static Future<Map<String, dynamic>> createSubCategory(int parentId, String name) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.createSubCategory(parentId),
      body: {"category_name": name},
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// UPDATE CATEGORY (PUT)
  /// ============================================================
  static Future<Map<String, dynamic>> updateCategory(int id, String name) async {
    final response = await ApiClient.put(
      endpoint: ApiUrls.categoryDetails(id),
      data: {"category_name": name},
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// DELETE CATEGORY
  /// ============================================================
  static Future<void> deleteCategory(int id, {bool deleteSubcategories = false}) async {
    await ApiClient.delete(
      endpoint: "${ApiUrls.categoryDetails(id)}${deleteSubcategories ? "?delete_subcategories=true" : ""}",
      requireAuth: true,
    );
  }

  /// ============================================================
  /// UPLOAD CATEGORY IMAGE
  /// ============================================================
  static Future<Map<String, dynamic>> uploadCategoryImage(int id, String imagePath) async {
    final response = await ApiClient.postMultipart(
      endpoint: ApiUrls.categoryImage(id),
      fields: {},
      files: {"image": imagePath},
      requireAuth: true,
    );

    return response;
  }

  /// ============================================================
  /// GET SELLER BRANCHES
  /// ============================================================
  static Future<Map<String, dynamic>> getBranches() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.sellerBranches,
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    return response;
  }

  /// ============================================================
  /// REQUEST JOIN BRANCH BY CODE
  /// ============================================================
  static Future<void> requestJoinBranch(String code) async {
    await ApiClient.post(
      endpoint: ApiUrls.branchRequestByCode,
      body: {"branch_code": code},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// LEAVE BRANCH
  /// ============================================================
  static Future<void> leaveBranch(int id) async {
    await ApiClient.post(
      endpoint: ApiUrls.leaveBranch(id),
      body: {},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// CANCEL BRANCH REQUEST
  /// ============================================================
  static Future<void> cancelBranchRequest(int id) async {
    await ApiClient.post(
      endpoint: ApiUrls.cancelBranchRequest(id),
      body: {},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// GET DELIVERY CHALLANS
  /// ============================================================
  static Future<List<dynamic>> getDeliveryChallans() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.sellerChallans,
      requireAuth: true,
    );
    if (response == null) {
      throw Exception("Failed to fetch challans");
    }
    if (response is Map<String, dynamic>) {
      if (response.containsKey("results")) {
        return response["results"] is List ? response["results"] : [];
      } else if (response.containsKey("data")) {
        return response["data"] is List ? response["data"] : [];
      }
    }
    return response is List ? response : [];
  }

  /// ============================================================
  /// GET CHALLAN DETAILS
  /// ============================================================
  static Future<Map<String, dynamic>> getChallanDetails(int id) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.challanDetails(id),
      requireAuth: true,
    );
    return response;
  }

  /// ============================================================
  /// DISPATCH CHALLAN
  /// ============================================================
  static Future<void> dispatchChallan(int id) async {
    await ApiClient.post(
      endpoint: ApiUrls.dispatchChallan(id),
      body: {},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// GET PRODUCTS
  /// ============================================================
  static Future<List<dynamic>> getProducts() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.products,
      requireAuth: true,
    );
    if (response == null) {
      throw Exception("Failed to fetch products");
    }
    if (response is Map<String, dynamic> && response.containsKey("data")) {
      return response["data"] is List ? response["data"] : [];
    }
    return response is List ? response : [];
  }

  /// ============================================================
  /// CREATE PRODUCT
  /// ============================================================
  static Future<void> createProduct(Map<String, dynamic> data) async {
    await ApiClient.post(
      endpoint: ApiUrls.products,
      body: data,
      requireAuth: true,
    );
  }

  /// ============================================================
  /// GET CONTRACTS
  /// ============================================================
  static Future<List<dynamic>> getContracts() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.contracts,
      requireAuth: true,
    );
    if (response == null) {
      throw Exception("Failed to fetch contracts");
    }
    if (response is Map<String, dynamic>) {
      if (response.containsKey("results")) {
        return response["results"] is List ? response["results"] : [];
      } else if (response.containsKey("data")) {
        return response["data"] is List ? response["data"] : [];
      }
    }
    return response is List ? response : [];
  }
}
