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
      return response.map((e) => SellerCompanyModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } else if (response is Map<String, dynamic> && response.containsKey("data")) {
      return (response["data"] as List).map((e) => SellerCompanyModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } else if (response is Map<String, dynamic>) {
      return [SellerCompanyModel.fromJson(response)];
    } else {
      return [];
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

  static Future<Map<String, dynamic>> editCompany(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.patch(
      endpoint: "/api/company/$id/",
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
      throw Exception(
        response["message"] ?? "Failed to fetch company dropdown",
      );
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
  static Future<void> setPrimaryCompany(dynamic id) async {
    await ApiClient.post(
      endpoint: ApiUrls.setPrimaryCompany(int.tryParse(id.toString()) ?? 0),
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
      throw Exception(
        response["message"] ?? "Failed to fetch categories dashboard",
      );
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

    // The old /message/ endpoint answers with a redirect for mobile, so use the thread API.
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerInterestThread(productId, interestId),
      body: body,
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to send counter offer");
    }
    return response;
  }

  static Future<Map<String, dynamic>> getOfferInterestThread(int productId, int interestId) async {
    final response = await ApiClient.get(endpoint: ApiUrls.offerInterestThread(productId, interestId), requireAuth: true);
    return _asMap(response, "Failed to load negotiation");
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

  /// ============================================================
  /// MASTER DATA (BRANDS, CATEGORIES, TAGS)
  /// ============================================================
  static Future<List<dynamic>> getBrandsList() async {
    try {
      final response = await ApiClient.get(endpoint: ApiUrls.brandsDropdown, requireAuth: true);
      if (response is List && response.isNotEmpty) return response;
      if (response is Map<String, dynamic>) {
        if (response["data"] is List && (response["data"] as List).isNotEmpty) return response["data"];
        if (response["results"] is List && (response["results"] as List).isNotEmpty) return response["results"];
      }
    } catch (_) {}

    try {
      final response = await ApiClient.get(endpoint: ApiUrls.brands, requireAuth: true);
      if (response is List) return response;
      if (response is Map<String, dynamic> && response["results"] is List) return response["results"];
      if (response is Map<String, dynamic> && response["data"] is List) return response["data"];
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createBrand(String name, {String? description}) async {
    final body = {"name": name, if (description != null && description.isNotEmpty) "description": description};
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.brands,
        body: body,
        requireAuth: true,
      );
      if (response is Map<String, dynamic>) return response;
    } catch (_) {
      final response = await ApiClient.post(
        endpoint: "/api/admin/brand/create/",
        body: body,
        requireAuth: true,
      );
      if (response is Map<String, dynamic>) return response;
    }
    return {"success": true, "message": "Brand created successfully"};
  }

  static Future<List<dynamic>> getCategoryTree() async {
    try {
      final response = await ApiClient.get(endpoint: ApiUrls.categoriesTree, requireAuth: true);
      if (response is List && response.isNotEmpty) return response;
      if (response is Map<String, dynamic>) {
        if (response["data"] is List && (response["data"] as List).isNotEmpty) return response["data"];
        if (response["categories"] is List && (response["categories"] as List).isNotEmpty) return response["categories"];
        if (response["results"] is List && (response["results"] as List).isNotEmpty) return response["results"];
      }
    } catch (_) {}

    try {
      final fallbackRes = await ApiClient.get(endpoint: ApiUrls.categories, requireAuth: true);
      if (fallbackRes is List) return fallbackRes;
      if (fallbackRes is Map<String, dynamic> && fallbackRes["data"] is List) return fallbackRes["data"];
      if (fallbackRes is Map<String, dynamic> && fallbackRes["results"] is List) return fallbackRes["results"];
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getTagsList() async {
    try {
      final response = await ApiClient.get(endpoint: ApiUrls.tagsDropdown, requireAuth: true);
      if (response is List && response.isNotEmpty) return response;
      if (response is Map<String, dynamic>) {
        if (response["data"] is List && (response["data"] as List).isNotEmpty) return response["data"];
        if (response["results"] is List && (response["results"] as List).isNotEmpty) return response["results"];
      }
    } catch (_) {}

    try {
      final response = await ApiClient.get(endpoint: ApiUrls.tagsList, requireAuth: true);
      if (response is List) return response;
      if (response is Map<String, dynamic> && response["results"] is List) return response["results"];
      if (response is Map<String, dynamic> && response["data"] is List) return response["data"];
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createTag(String name) async {
    final body = {"name": name, "tag_name": name};
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.addTag,
        body: body,
        requireAuth: true,
      );
      if (response is Map<String, dynamic>) return response;
    } catch (_) {
      final response = await ApiClient.post(
        endpoint: ApiUrls.tags,
        body: body,
        requireAuth: true,
      );
      if (response is Map<String, dynamic>) return response;
    }
    return {"success": true, "message": "Tag created successfully"};
  }

  static Map<String, dynamic> _asMap(dynamic response, String error) {
    if (response is Map<String, dynamic>) return response;
    throw Exception(error);
  }

  static String _withQuery(String endpoint, Map<String, String?> params) {
    final query = {
      for (final entry in params.entries)
        if (entry.value != null && entry.value!.isNotEmpty) entry.key: entry.value!,
    };
    return query.isEmpty ? endpoint : "$endpoint?${Uri(queryParameters: query).query}";
  }

  /// ============================================================
  /// OFFER MANAGEMENT (edit, delete, stock history, buyer interests)
  /// ============================================================
  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> body) async {
    final response = await ApiClient.post(endpoint: ApiUrls.offerCreate, body: body, requireAuth: true);
    return _asMap(response, "Failed to create offer");
  }

  static Future<Map<String, dynamic>> getOfferDetail(int productId) async {
    final response = await ApiClient.get(endpoint: ApiUrls.offerDetail(productId), requireAuth: true);
    return _asMap(response, "Failed to load offer");
  }

  static Future<Map<String, dynamic>> updateOffer(int productId, Map<String, dynamic> body) async {
    final response = await ApiClient.patch(endpoint: ApiUrls.offerUpdate(productId), data: body, requireAuth: true);
    return _asMap(response, "Failed to update offer");
  }

  static Future<Map<String, dynamic>> deleteOffer(int productId) async {
    final response = await ApiClient.delete(endpoint: ApiUrls.offerDelete(productId), requireAuth: true);
    return _asMap(response, "Failed to delete offer");
  }

  static Future<Map<String, dynamic>> getOfferStockHistory(int productId, {int page = 1}) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.offerStockHistory(productId)}?page=$page",
      requireAuth: true,
    );
    return _asMap(response, "Failed to load stock history");
  }

  static Future<Map<String, dynamic>> approveBuyerInterest(int productId, int interestId, {String remark = ""}) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerApproveBuyer(productId),
      body: {"interest_id": interestId, "seller_remark": remark},
      requireAuth: true,
    );
    return _asMap(response, "Failed to approve buyer interest");
  }

  static Future<Map<String, dynamic>> rejectBuyerInterest(int productId, int interestId, {String remark = ""}) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerRejectBuyer(productId),
      body: {"interest_id": interestId, "seller_remark": remark},
      requireAuth: true,
    );
    return _asMap(response, "Failed to reject buyer interest");
  }

  /// ============================================================
  /// BUYER REQUIREMENTS (RFQ) - single API
  /// ============================================================
  static Future<Map<String, dynamic>> getBuyerRequirements({String tab = "incoming", String? search, String? status, int page = 1}) async {
    final response = await ApiClient.get(
      endpoint: _withQuery(ApiUrls.buyerRequirements, {"tab": tab, "search": search, "status": status, "page": "$page"}),
      requireAuth: true,
    );
    return _asMap(response, "Failed to load buyer requirements");
  }

  static Future<Map<String, dynamic>> getBuyerRequirement(String rfqId, {int? quotationId}) async {
    final response = await ApiClient.get(
      endpoint: _withQuery(ApiUrls.buyerRequirementDetail(rfqId), {"quotation_id": quotationId?.toString()}),
      requireAuth: true,
    );
    return _asMap(response, "Failed to load buyer requirement");
  }

  static Future<Map<String, dynamic>> buyerRequirementAction(String rfqId, Map<String, dynamic> body) async {
    final response = await ApiClient.post(endpoint: ApiUrls.buyerRequirementDetail(rfqId), body: body, requireAuth: true);
    return _asMap(response, "Request failed");
  }

  /// ============================================================
  /// CONSIGNMENTS - single API
  /// ============================================================
  static Future<Map<String, dynamic>> getConsignments({String? workflowStatus, String? search, int page = 1}) async {
    final response = await ApiClient.get(
      endpoint: _withQuery(ApiUrls.consignments, {"workflow_status": workflowStatus, "search": search, "page": "$page"}),
      requireAuth: true,
    );
    return _asMap(response, "Failed to load consignments");
  }

  static Future<Map<String, dynamic>> getConsignmentDetail(int contractId) async {
    final response = await ApiClient.get(endpoint: ApiUrls.consignmentDetail(contractId), requireAuth: true);
    return _asMap(response, "Failed to load consignment");
  }

  static Future<Map<String, dynamic>> consignmentAction(int contractId, String action) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.consignmentDetail(contractId),
      body: {"action": action},
      requireAuth: true,
    );
    return _asMap(response, "Request failed");
  }

  /// ============================================================
  /// BUYER OFFERS (seller side)
  /// ============================================================
  static Future<List<dynamic>> getBuyerOfferRequests({String tab = "incoming", String? search, String? status}) async {
    final response = await ApiClient.get(
      endpoint: _withQuery(ApiUrls.buyerOffers, {"tab": tab, "search": search, "status": status}),
      requireAuth: true,
    );
    if (response is Map<String, dynamic> && response["buyer_offers"] is List) return response["buyer_offers"];
    if (response is List) return response;
    return [];
  }

  static Future<Map<String, dynamic>> getBuyerOfferRequest(int id) async {
    final response = await ApiClient.get(endpoint: ApiUrls.buyerOfferDetails(id), requireAuth: true);
    final map = _asMap(response, "Failed to load buyer offer");
    return map["buyer_offer"] is Map<String, dynamic> ? map["buyer_offer"] : map;
  }

  static Future<Map<String, dynamic>> buyerOfferAction(int id, Map<String, dynamic> body) async {
    final response = await ApiClient.post(endpoint: ApiUrls.buyerOfferAction(id), body: body, requireAuth: true);
    return _asMap(response, "Request failed");
  }

  static Future<Map<String, dynamic>> deleteCompany(int companyId) async {
    // DELETE answers 204 with an empty body, which the client returns as an empty map.
    return ApiClient.delete(endpoint: ApiUrls.companyDetails(companyId), requireAuth: true);
  }

  static Future<List<Map<String, dynamic>>> getPublicBranches() async {
    final response = await ApiClient.get(endpoint: ApiUrls.publicBranches, requireAuth: true);
    final list = response is Map<String, dynamic> ? response['data'] : response;
    return (list is List ? list : const []).whereType<Map<String, dynamic>>().toList();
  }

  /// ============================================================
  /// QUALITY TAGS (edit / delete; delete never forces removal from users)
  /// ============================================================
  static Future<Map<String, dynamic>> updateTag(int tagId, String name) async {
    final response = await ApiClient.patch(endpoint: "${ApiUrls.tags}$tagId/", data: {"tag_name": name}, requireAuth: true);
    return _asMap(response, "Failed to update tag");
  }

  static Future<Map<String, dynamic>> deleteTag(int tagId) async {
    final response = await ApiClient.delete(endpoint: "${ApiUrls.tags}$tagId/", requireAuth: true);
    return _asMap(response, "Failed to delete tag");
  }

  /// ============================================================
  /// KYC RE-APPROVAL
  /// ============================================================
  static Future<Map<String, dynamic>> requestKycApproval() async {
    final response = await ApiClient.post(endpoint: ApiUrls.kycRequestApproval, body: {}, requireAuth: true);
    return _asMap(response, "Failed to send KYC request");
  }
}
