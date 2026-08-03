import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';

class BuyerServices {
  /// ============================================================
  /// GET BUYER DASHBOARD
  /// ============================================================
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerDashboard,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// GET BUYER OFFERS
  /// ============================================================
  static Future<List<dynamic>> getOffers({String query = ""}) async {
    String endpoint = ApiUrls.buyerOffers;
    if (query.isNotEmpty) {
      endpoint += "?search=$query";
    }

    final response = await ApiClient.get(
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["buyer_offers"] ?? [];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch buyer offers");
    }
  }

  /// ============================================================
  /// GET TODAY'S OFFERS
  /// ============================================================
  static Future<List<dynamic>> getTodayOffers() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerTodayOffers,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["results"] ?? [];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch today's offers");
    }
  }

  /// ============================================================
  /// GET PENDING OFFERS
  /// ============================================================
  static Future<List<dynamic>> getPendingOffers() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerPendingOffers,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["results"] ?? [];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch pending offers");
    }
  }

  /// ============================================================
  /// GET PREVIOUS OFFERS
  /// ============================================================
  static Future<List<dynamic>> getPreviousOffers() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerPreviousOffers,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["results"] ?? [];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch previous offers");
    }
  }

  /// ============================================================
  /// GET MY INTERESTS
  /// ============================================================
  static Future<List<dynamic>> getMyInterests() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerMyInterests,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    if (response["success"] == true) {
      return response["results"] ?? [];
    } else {
      throw Exception(response["message"] ?? "Failed to fetch my interests");
    }
  }
}
