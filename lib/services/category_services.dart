import '../comman/api_url.dart';
import '../modules/category/model/subcategory_model.dart';
import '../network/api_client.dart';
import '../modules/category/model/category_model.dart';

class CategoryService {
  /// ===============================
  /// FETCH BUYER CATEGORIES
  /// ===============================
  static Future<List<CategoryModel>> fetchBuyerCategories() async {
    try {
      final dynamic response = await ApiClient.get(
        endpoint: ApiUrls.buyerCategories,
        requireAuth: true,
      );

      print("📥 BUYER CATEGORIES RESPONSE: $response");

      if (response != null) {
        List<CategoryModel> buyerCats = [];
        
        if (response is Map<String, dynamic> && response["data"] is Map<String, dynamic>) {
          final data = response["data"] as Map<String, dynamic>;
          final allCats = data["all_categories"] is List ? (data["all_categories"] as List) : [];
          final assignedIds = (data["assigned_category_ids"] is List)
              ? (data["assigned_category_ids"] as List).map((e) => int.tryParse(e.toString()) ?? 0).toSet()
              : <int>{};
          final pendingIds = (data["pending_category_ids"] is List)
              ? (data["pending_category_ids"] as List).map((e) => int.tryParse(e.toString()) ?? 0).toSet()
              : <int>{};

          // Helper to check if a category is a dummy or test category
          bool isDummyCategory(String name) {
            final t = name.trim().toLowerCase();
            if (t.isEmpty) return true;
            if (t == 'test' ||
                t == 'xyz' ||
                t == 'sub' ||
                t == 'teat sub' ||
                t == 'test category' ||
                t == 'testing' ||
                t.startsWith('test') ||
                t.endsWith('test') ||
                t.contains('test') ||
                RegExp(r'^(.)\1+$').hasMatch(t)) {
              return true;
            }
            return false;
          }

          // Build a map of requested timestamps from data["requests"]
          final Map<int, String> requestedAtMap = {};
          if (data["requests"] is List) {
            for (var req in (data["requests"] as List)) {
              if (req is Map<String, dynamic> && req["categories"] is List) {
                final reqTime = req["requested_at"]?.toString() ?? req["created_at"]?.toString();
                if (reqTime != null && reqTime.isNotEmpty) {
                  for (var cat in (req["categories"] as List)) {
                    if (cat is Map<String, dynamic>) {
                      final id = int.tryParse((cat["id"] ?? 0).toString()) ?? 0;
                      if (id > 0 && !requestedAtMap.containsKey(id)) {
                        requestedAtMap[id] = reqTime;
                      }
                    }
                  }
                }
              }
            }
          }

          // Map all_categories with their status (matching Buyer web panel)
          if (allCats.isNotEmpty) {
            for (var c in allCats) {
              if (c is Map<String, dynamic>) {
                final id = int.tryParse((c["id"] ?? 0).toString()) ?? 0;
                final name = (c["category_name"] ?? c["name"] ?? "").toString();
                if (id > 0 && !isDummyCategory(name)) {
                  String status = "Request";
                  if (assignedIds.contains(id)) {
                    status = "Approved";
                  } else if (pendingIds.contains(id)) {
                    status = "Pending";
                  }
                  final reqCreatedAt = requestedAtMap[id] ?? c["created_at"] ?? c["requested_at"];
                  buyerCats.add(CategoryModel.fromJson({
                    ...c,
                    "status": status,
                    if (reqCreatedAt != null) "created_at": reqCreatedAt,
                  }));
                }
              }
            }
          } else if (assignedIds.isNotEmpty || pendingIds.isNotEmpty) {
            // Fallback if all_categories was not provided
            for (var c in allCats) {
              if (c is Map<String, dynamic>) {
                final id = int.tryParse((c["id"] ?? 0).toString()) ?? 0;
                final name = (c["category_name"] ?? c["name"] ?? "").toString();
                if ((assignedIds.contains(id) || pendingIds.contains(id)) && !isDummyCategory(name)) {
                  final status = assignedIds.contains(id) ? "Approved" : "Pending";
                  final reqCreatedAt = requestedAtMap[id] ?? c["created_at"] ?? c["requested_at"];
                  buyerCats.add(CategoryModel.fromJson({
                    ...c,
                    "status": status,
                    if (reqCreatedAt != null) "created_at": reqCreatedAt,
                  }));
                }
              }
            }
          }

          // 2. Also check requests list if buyerCats is still empty
          if (buyerCats.isEmpty && data["requests"] is List) {
            final Set<int> seenIds = {};
            for (var req in (data["requests"] as List)) {
              if (req is Map<String, dynamic> && req["categories"] is List) {
                final reqStatus = req["status"]?.toString() ?? "Approved";
                final reqCreatedAt = req["requested_at"] ?? req["created_at"];
                for (var cat in (req["categories"] as List)) {
                  if (cat is Map<String, dynamic>) {
                    final id = int.tryParse((cat["id"] ?? 0).toString()) ?? 0;
                    final name = (cat["category_name"] ?? cat["name"] ?? "").toString();
                    if (id > 0 && !seenIds.contains(id) && !isDummyCategory(name)) {
                      seenIds.add(id);
                      buyerCats.add(CategoryModel.fromJson({
                        ...cat,
                        "status": reqStatus,
                        "created_at": reqCreatedAt,
                      }));
                    }
                  }
                }
              }
            }
          }

          if (buyerCats.isNotEmpty) {
            return buyerCats;
          }
        } else if (response is List) {
          return response
              .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
              .where((c) {
                final t = c.categoryName.trim().toLowerCase();
                return t.isNotEmpty && !t.contains('test') && t != 'xyz' && t != 'sub';
              })
              .toList();
        }
      }
    } catch (e) {
      print("⚠️ Buyer categories API failed, falling back: $e");
    }

    final allSys = await fetchCategories();
    return allSys.where((c) {
      final t = c.categoryName.trim().toLowerCase();
      return t.isNotEmpty && !t.contains('test') && t != 'xyz' && t != 'sub';
    }).toList();
  }

  /// ===============================
  /// FETCH CATEGORIES (ALL)
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
        if (response is Map<String, dynamic> && response["results"] is List) {
          return (response["results"] as List)
              .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
        throw Exception("Expected List but got ${response.runtimeType}");
      }

      final List<CategoryModel> categories = [];

      for (var item in response) {
        categories.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
      }

      return categories;
    } catch (e) {
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
    } catch (e) {
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

  /// ===============================
  /// REQUEST CATEGORY APPROVAL
  /// ===============================
  static Future<Map<String, dynamic>> requestCategoryApproval({
    required List<int> categoryIds,
    String? categoryName,
    String? note,
  }) async {
    final body = <String, dynamic>{
      if (categoryIds.isNotEmpty) "category_ids": categoryIds,
      if (categoryIds.isNotEmpty) "categories": categoryIds,
      if (categoryName != null && categoryName.trim().isNotEmpty) "category_name": categoryName.trim(),
      if (categoryName != null && categoryName.trim().isNotEmpty) "name": categoryName.trim(),
      "request_note": (note != null && note.trim().isNotEmpty) ? note.trim() : "Buyer requested category approval.",
      "note": (note != null && note.trim().isNotEmpty) ? note.trim() : "Buyer requested category approval.",
    };

    // 1. Primary endpoint: POST /api/buyer-categories/
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.buyerCategories,
        body: body,
        requireAuth: true,
      );
      return response;
    } catch (e) {
      print("POST /api/buyer-categories/ failed: $e");
    }

    // 2. Fallback: POST /api/buyer-categories/request/
    try {
      final response = await ApiClient.post(
        endpoint: "/api/buyer-categories/request/",
        body: body,
        requireAuth: true,
      );
      return response;
    } catch (e) {
      print("POST /api/buyer-categories/request/ failed: $e");
    }

    // 3. Fallback: POST /api/buyer/categories/request/
    try {
      final response = await ApiClient.post(
        endpoint: "/api/buyer/categories/request/",
        body: body,
        requireAuth: true,
      );
      return response;
    } catch (e) {
      print("POST /api/buyer/categories/request/ failed: $e");
      rethrow;
    }
  }
}
