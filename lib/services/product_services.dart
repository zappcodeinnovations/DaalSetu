import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/modules/products/model/product_model.dart';
import 'package:agro_broker/modules/products/model/offer_option_model.dart';
import 'package:agro_broker/modules/products/model/offer_interest_model.dart';
import 'package:agro_broker/network/api_client.dart';

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
        endpoint: ApiUrls.productImages, // "/api/product-images/"
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
    required String action,        // 'Add' or 'Remove'
    required String quantity,      // in QTL
    required String bags,          // number of bags
    required String packingKg,     // packing weight in kg
  }) async {
    try {
      // API expects 'mode' (add or reduce) instead of 'action'
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

      print("🔍 getOfferInterests RAW response type: ${response.runtimeType}");
      if (response is Map) {
        print("🔍 getOfferInterests Map keys: ${response.keys.toList()}");
      }
      if (response is List && response.isNotEmpty) {
        print("🔍 getOfferInterests first item keys: ${(response.first as Map).keys.toList()}");
      }

      List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map) {
        // Try common wrapper keys in order of likelihood
        final extracted = response['results'] ??
            response['data'] ??
            response['interests'] ??
            response['interest_list'];
        if (extracted is List) {
          data = extracted;
          if (data.isNotEmpty) {
            print("🔍 getOfferInterests extracted list[0] keys: ${(data.first as Map).keys.toList()}");
            print("🔍 getOfferInterests extracted list[0]: ${data.first}");
          }
        } else {
          print("⚠️ getOfferInterests: unexpected Map shape, keys=${response.keys.toList()}");
          data = [];
        }
      } else {
        data = [];
      }

      final interests = data
          .map((item) => OfferInterestModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      for (final i in interests) {
        print("🔍 Parsed interest: id=${i.id}, interestId=${i.interestId}, transactionId=${i.transactionId}, buyer=${i.buyerName}");
      }

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
  }) async {
    try {
      final body = {
        "interest_id": interestId,
        "decision": decision,
        "admin_remark": superadminRemark,
      };
      print("🔍 confirmOfferDeal: productId=$productId, body=$body");
      await ApiClient.post(
        endpoint: "/api/products/$productId/confirm-deal/",
        requireAuth: true,
        body: body,
      );
    } catch (e) {
      print("❌ confirmOfferDeal Error: $e");
      rethrow;
    }
  }

  /// Send a negotiation counter-offer message
  /// POST /api/offers/{product_id}/interests/{interest_id}/message/
  /// Body: { message, counter_price, counter_quantity }
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
