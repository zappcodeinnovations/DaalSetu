import '../comman/api_url.dart';
import '../modules/products/model/offer_interest_model.dart';
import '../modules/products/model/offer_option_model.dart';
import '../modules/products/model/product_model.dart';
import '../network/api_client.dart';

class ProductService {
  static Future<ProductModel> getProductDetail(int productId) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.products}$productId/",
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception("Invalid product detail response");
    }
    return ProductModel.fromJson(response);
  }

  static Future<List<OfferOption>> getParentCategories() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.parentCategories,
      requireAuth: true,
    );
    final data = response is Map ? response["data"] : null;
    return (data as List? ?? [])
        .map(
          (item) => OfferOption(
            id: item["id"] as int,
            name: item["category_name"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static Future<List<OfferOption>> getCategoryBrands(int categoryId) async {
    final response = await ApiClient.get(
      endpoint: "/api/categories/$categoryId/brands/",
      requireAuth: true,
    );
    final data = response is Map ? response["data"] : null;
    return (data as List? ?? [])
        .map(
          (item) => OfferOption(
            id: item["id"] as int,
            name: item["brand_name"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static Future<List<OfferOption>> getSellers() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.users,
      requireAuth: true,
    );
    return (response as List? ?? [])
        .where((item) => item["role"] == "seller" && item["is_active"] == true)
        .map(
          (item) => OfferOption(
            id: item["id"] as int,
            name: [item["first_name"], item["last_name"]]
                .where((value) => value?.toString().trim().isNotEmpty ?? false)
                .join(" "),
            subtitle: item["mobile"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static Future<List<OfferOption>> getSellerCompanies(int sellerId) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.company}?seller=$sellerId",
      requireAuth: true,
    );
    return (response as List? ?? [])
        .map(
          (item) => OfferOption(
            id: item["id"] as int,
            name: item["legal_name"]?.toString() ?? "",
            subtitle: [item["city"], item["state"]]
                .where((value) => value?.toString().trim().isNotEmpty ?? false)
                .join(", "),
          ),
        )
        .toList();
  }

  static Future<List<OfferBranch>> getSellerBranches(int sellerId) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.sellerBranches}?seller=$sellerId",
      requireAuth: true,
    );
    final data = response is Map ? response["data"] : null;
    final branches = data is Map ? data["my_branches"] : null;
    return (branches as List? ?? [])
        .map(
          (item) => OfferBranch(
            id: item["id"] as int,
            name: item["location_name"]?.toString() ?? "",
            code: item["branch_code"]?.toString() ?? "",
            city: item["city"]?.toString() ?? "",
            state: item["state"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> body) {
    return ApiClient.post(
      endpoint: ApiUrls.products,
      body: body,
      requireAuth: true,
    );
  }

  static Future<dynamic> uploadProductVideo({
    required int productId,
    required String videoPath,
  }) {
    return ApiClient.postMultipart(
      endpoint: ApiUrls.productVideos,
      fields: {
        "product": productId.toString(),
        "title": "Offer video",
        "is_primary": "true",
      },
      files: {"video": videoPath},
      requireAuth: true,
    );
  }

  /// ===============================
  /// GET PRODUCTS
  /// ===============================
  static Future<List<ProductModel>> getProducts() async {
    try {
      final dynamic response = await ApiClient.get(
        endpoint: ApiUrls.products,
        requireAuth: true,
      );

      print("📥 PRODUCT API RESPONSE: $response");

      if (response == null) {
        throw Exception("Invalid response from product API");
      }

      if (response is! List) {
        throw Exception("Expected List but got ${response.runtimeType}");
      }

      final List<ProductModel> products = [];

      for (var item in response) {
        products.add(ProductModel.fromJson(Map<String, dynamic>.from(item)));
      }

      return products;
    } catch (e) {
      print("❌ ProductService Error: $e");
      rethrow;
    }
  }

  static Future<dynamic> uploadProductImage({
    required int productId,
    required String imagePath,
    bool isPrimary = false,
  }) async {
    try {
      final response = await ApiClient.postMultipart(
        endpoint: ApiUrls.productImages,
        requireAuth: true,
        fields: {
          "product": productId.toString(),
          "is_primary": isPrimary.toString(),
        },
        files: {"image": imagePath},
      );

      print("📷 IMAGE UPLOAD RESPONSE: $response");

      return response;
    } catch (e) {
      print("❌ IMAGE UPLOAD ERROR: $e");
      rethrow;
    }
  }

  /// ===============================
  /// CREATE PRODUCT
  /// ===============================
  static Future<dynamic> createProduct({
    required String title,
    required String baseAmount,
    required String loadingLocation,
    required String categoryId,
    String? sellerId,
  }) async {
    try {
      Map<String, dynamic> body = {
        "title": title,
        "base_amount": baseAmount,
        "loading_location": loadingLocation,
        "category": categoryId,
      };

      /// Admin assigns seller
      if (sellerId != null && sellerId.isNotEmpty) {
        body["seller"] = sellerId;
      }

      final response = await ApiClient.post(
        endpoint: ApiUrls.products,
        requireAuth: true,
        body: body,
      );

      print("✅ PRODUCT CREATE RESPONSE: $response");

      return response;
    } catch (e) {
      print("❌ CREATE PRODUCT ERROR: $e");
      rethrow;
    }
  }

  static Future<ProductModel> updateProduct({
    required int productId,
    required String title,
    required String description,
    required String amount,
    required String loadingLocation,
    int? categoryId,
  }) async {
    final body = <String, dynamic>{
      "title": title,
      "description": description,
      "amount": amount,
      "loading_location": loadingLocation,
      if (categoryId != null) "category_id": categoryId,
    };

    final response = await ApiClient.patch(
      endpoint: "${ApiUrls.products}$productId/",
      data: body,
      requireAuth: true,
    );

    return ProductModel.fromJson(response);
  }

  static Future<void> deleteProduct(int productId) async {
    await ApiClient.delete(
      endpoint: "${ApiUrls.products}$productId/",
      requireAuth: true,
    );
  }

  /// ===============================
  /// UPDATE STOCK (Manage Stock)
  /// POST /api/offers/{product_id}/update-stock/
  /// action: 'Add' or 'Remove'
  /// ===============================
  static Future<Map<String, dynamic>> updateStock({
    required int productId,
    required String action,
    required String quantity,
    required String bags,
    required String packingKg,
  }) async {
    try {
      String apiMode = action.toLowerCase();
      if (apiMode == 'remove') {
        apiMode = 'reduce';
      }

      final body = <String, dynamic>{
        'mode': apiMode,
      };

      if (quantity.isNotEmpty) body['quantity'] = quantity;
      if (bags.isNotEmpty) body['bag_count'] = bags;
      if (packingKg.isNotEmpty) body['packing_weight_kg'] = packingKg;

      print('📦 updateStock: productId=$productId, body=$body');

      final response = await ApiClient.post(
        endpoint: '/api/offers/$productId/update-stock/',
        body: body,
        requireAuth: true,
      );

      print('✅ updateStock response: $response');
      return response;
    } catch (e) {
      print('❌ updateStock Error: $e');
      rethrow;
    }
  }

  /// ===============================
  /// OFFER INTERESTS & APPROVAL
  /// ===============================
  static Future<List<OfferInterestModel>> getOfferInterests(int productId) async {
    try {
      final response = await ApiClient.get(
        endpoint: "/api/offers/$productId/interests/",
        requireAuth: true,
      );

      List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map) {
        final extracted = response['results'] ??
            response['data'] ??
            response['interests'] ??
            response['interest_list'];
        if (extracted is List) {
          data = extracted;
        } else {
          data = [];
        }
      } else {
        data = [];
      }

      final interests = data
          .map((item) => OfferInterestModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return interests;
    } catch (e) {
      print("❌ getOfferInterests Error: $e");
      if (e.toString().toLowerCase().contains('not found')) {
        return [];
      }
      rethrow;
    }
  }

  static Future<void> confirmOfferDeal({
    required int productId,
    required int interestId,
    required String decision,
    String superadminRemark = '',
    int? subAdminId,
  }) async {
    final body = {
      "interest_id": interestId,
      "decision": decision,
      "admin_remark": superadminRemark,
      if (subAdminId != null) "assigned_sub_admin_id": subAdminId,
    };
    try {
      await ApiClient.post(
        endpoint: "/api/products/$productId/confirm-deal/",
        requireAuth: true,
        body: body,
      );
    } catch (e) {
      if (e.toString().contains("404") || e.toString().contains("Not Found")) {
        try {
          await ApiClient.post(
            endpoint: ApiUrls.offerConfirmDeal(productId),
            requireAuth: true,
            body: body,
          );
          return;
        } catch (_) {}
      }
      print("❌ confirmOfferDeal Error: $e");
      rethrow;
    }
  }

  /// Send a negotiation counter-offer message
  static Future<void> sendNegotiationMessage({
    required int productId,
    required int interestId,
    required String message,
    required String counterPrice,
    required String counterQuantity,
  }) async {
    try {
      await ApiClient.post(
        endpoint: "/api/offers/$productId/interests/$interestId/message/",
        requireAuth: true,
        body: {
          "message": message,
          "counter_price": counterPrice,
          "counter_quantity": counterQuantity,
        },
      );
    } catch (e) {
      print("❌ sendNegotiationMessage Error: $e");
      rethrow;
    }
  }
}
