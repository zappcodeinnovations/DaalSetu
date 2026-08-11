import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/network/api_client.dart';

class ProductService {
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
}
