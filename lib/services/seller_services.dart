import '../network/api_client.dart';
import '../comman/api_url.dart';
import '../modules/seller/company/model/seller_company_model.dart';

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

  /// ============================================================
  /// OFFER INTERESTS & NEGOTIATIONS
  /// ============================================================
  static Future<Map<String, dynamic>> getOfferInterests(int productId, {String mode = 'seller'}) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.offerInterests(productId)}?mode=$mode",
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to fetch offer interests");
    }
    return response;
  }

  static Future<Map<String, dynamic>> sendCounterOfferMessage(
    int productId,
    int interestId, {
    required String counterPrice,
    required String counterQuantity,
    int? counterBagCount,
    String? counterPackingWeightKg,
  }) async {
    final body = {
      "counter_price": counterPrice,
      "counter_quantity": counterQuantity,
      if (counterBagCount != null) "counter_bag_count": counterBagCount,
      if (counterPackingWeightKg != null) "counter_packing_weight_kg": counterPackingWeightKg,
    };

    final response = await ApiClient.post(
      endpoint: ApiUrls.offerNegotiationMessage(productId, interestId),
      body: body,
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to send counter offer");
    }
    return response;
  }

  static Future<Map<String, dynamic>> confirmOfferDeal(int productId, int interestId, {String? adminRemark, int? subAdminId}) async {
    final body = {
      "interest_id": interestId,
      if (adminRemark != null) "admin_remark": adminRemark,
      if (subAdminId != null) "assigned_sub_admin_id": subAdminId,
    };
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerConfirmDeal(productId),
      body: body,
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to confirm deal");
    }
    return response;
  }

  /// ============================================================
  /// STOCK & ACTIVE TOGGLE
  /// ============================================================
  static Future<Map<String, dynamic>> updateOfferStock(
    int productId, {
    required String mode,
    required String operation,
    required String quantity,
  }) async {
    final body = {
      "mode": mode,
      "operation": operation,
      "quantity": quantity,
    };
    final response = await ApiClient.patch(
      endpoint: ApiUrls.offerUpdateStock(productId),
      data: body,
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to update stock");
    }
    return response;
  }

  static Future<Map<String, dynamic>> toggleOfferStatus(int productId, bool isActive) async {
    final response = await ApiClient.patch(
      endpoint: ApiUrls.offerToggle(productId),
      data: {"is_active": isActive},
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to toggle offer status");
    }
    return response;
  }

  /// ============================================================
  /// PRODUCT IMAGES & VIDEOS
  /// ============================================================
  static Future<List<dynamic>> getProductImages({int? productId}) async {
    String endpoint = ApiUrls.productImages;
    if (productId != null) {
      endpoint += "?product=$productId";
    }
    final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);
    if (response is List) return response;
    if (response is Map<String, dynamic> && response["results"] is List) return response["results"];
    return [];
  }

  static Future<Map<String, dynamic>> uploadProductImage(int productId, String imagePath, {bool isPrimary = true}) async {
    final response = await ApiClient.postMultipart(
      endpoint: ApiUrls.productImages,
      fields: {
        "product": productId.toString(),
        "is_primary": isPrimary.toString(),
      },
      files: {"image": imagePath},
      requireAuth: true,
    );
    return response;
  }

  static Future<void> deleteProductImage(int imageId) async {
    await ApiClient.delete(endpoint: ApiUrls.productImageDetail(imageId), requireAuth: true);
  }

  static Future<List<dynamic>> getProductVideos({int? productId}) async {
    String endpoint = ApiUrls.productVideos;
    if (productId != null) {
      endpoint += "?product=$productId";
    }
    final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);
    if (response is List) return response;
    if (response is Map<String, dynamic> && response["results"] is List) return response["results"];
    return [];
  }

  static Future<Map<String, dynamic>> uploadProductVideo(int productId, String videoPath, String title, {bool isPrimary = true}) async {
    final response = await ApiClient.postMultipart(
      endpoint: ApiUrls.productVideos,
      fields: {
        "product": productId.toString(),
        "title": title,
        "is_primary": isPrimary.toString(),
      },
      files: {"video": videoPath},
      requireAuth: true,
    );
    return response;
  }

  static Future<void> deleteProductVideo(int videoId) async {
    await ApiClient.delete(endpoint: ApiUrls.productVideoDetail(videoId), requireAuth: true);
  }

  /// ============================================================
  /// TAGS DROPDOWN
  /// ============================================================
  static Future<List<dynamic>> getTagsDropdown() async {
    final response = await ApiClient.get(endpoint: ApiUrls.tagsDropdown, requireAuth: true);
    if (response is List) return response;
    if (response is Map<String, dynamic> && response["data"] is List) return response["data"];
    return [];
  }

  /// ============================================================
  /// BUYER REQUIREMENTS / RFQS & QUOTING
  /// ============================================================
  static Future<List<dynamic>> getBuyerRFQs({String? categoryId, String? search}) async {
    String endpoint = ApiUrls.sellerRFQs;
    final Map<String, String> queryParams = {};
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['category'] = categoryId;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (queryParams.isNotEmpty) {
      endpoint += "?${Uri(queryParameters: queryParams).query}";
    }

    final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);
    if (response is List) return response;
    if (response is Map<String, dynamic> && response["rfqs"] is List) return response["rfqs"];
    if (response is Map<String, dynamic> && response["results"] is List) return response["results"];
    if (response is Map<String, dynamic> && response["data"] is List) return response["data"];
    return [];
  }

  static Future<Map<String, dynamic>> submitRFQQuote(int rfqId, Map<String, dynamic> body) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.submitRFQQuote(rfqId),
      body: body,
      requireAuth: true,
    );
    if (response is Map<String, dynamic>) return response;
    return {"success": true, "message": "Quote submitted successfully"};
  }

  /// ============================================================
  /// CONTRACTS & DELIVERY CHALLANS
  /// ============================================================
  static Future<List<dynamic>> getSellerContracts() async {
    final response = await ApiClient.get(endpoint: ApiUrls.mobileContracts, requireAuth: true);
    if (response is List) return response;
    if (response is Map<String, dynamic> && response["results"] is List) return response["results"];
    if (response is Map<String, dynamic> && response["data"] is List) return response["data"];
    return [];
  }

  static Future<Map<String, dynamic>> getContractDetails(int contractId) async {
    final response = await ApiClient.get(endpoint: ApiUrls.mobileContractDetails(contractId), requireAuth: true);
    if (response is Map<String, dynamic>) return response;
    return {};
  }

  static Future<Map<String, dynamic>> dispatchDeliveryChallan(int challanId) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.sellerDispatchChallan(challanId),
      body: {},
      requireAuth: true,
    );
    if (response is Map<String, dynamic>) return response;
    return {"success": true, "message": "Delivery challan dispatched successfully"};
  }

  /// ============================================================
  /// SELLER COMPANY BRANCHES
  /// ============================================================
  static Future<Map<String, dynamic>> getSellerBranches() async {
    final response = await ApiClient.get(endpoint: ApiUrls.sellerBranches, requireAuth: true);
    if (response is Map<String, dynamic>) return response;
    return {};
  }

  static Future<Map<String, dynamic>> getBranchDetails(int branchId) async {
    final response = await ApiClient.get(endpoint: ApiUrls.branchDetails(branchId), requireAuth: true);
    if (response is Map<String, dynamic>) return response;
    return {};
  }

  static Future<Map<String, dynamic>> requestBranchByCode(String branchCode) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.requestBranchByCode,
      body: {"branch_code": branchCode},
      requireAuth: true,
    );
    if (response is Map<String, dynamic>) return response;
    return {"success": true, "message": "Branch join request submitted successfully"};
  }

  static Future<Map<String, dynamic>> cancelBranchRequest(int branchId) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.cancelBranchRequest(branchId),
      body: {},
      requireAuth: true,
    );
    if (response is Map<String, dynamic>) return response;
    return {"success": true, "message": "Branch request cancelled successfully"};
  }

  static Future<Map<String, dynamic>> leaveBranch(int branchId) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.leaveBranch(branchId),
      body: {},
      requireAuth: true,
    );
    if (response is Map<String, dynamic>) return response;
    return {"success": true, "message": "Left branch successfully"};
  }

  static Future<Map<String, dynamic>> createBranch(Map<String, dynamic> body) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.createBranch,
      body: body,
      requireAuth: true,
    );
    if (response is Map<String, dynamic>) return response;
    return {"success": true, "message": "Branch created successfully"};
  }
}
