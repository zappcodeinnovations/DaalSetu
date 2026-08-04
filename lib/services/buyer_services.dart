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
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerTodayOffers,
        requireAuth: true,
      );

      if (response == null || response is! Map<String, dynamic>) {
        return [];
      }

      // Check multiple keys to be safe
      return response["results"] ?? response["buyer_offers"] ?? response["data"] ?? [];
    } catch (e) {
      print("⚠️ Today's Offers API might not exist or failed: $e");
      // Fallback to general offers if today's fails
      return await getOffers();
    }
  }

  /// ============================================================
  /// GET PENDING OFFERS
  /// ============================================================
  static Future<List<dynamic>> getPendingOffers() async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerPendingOffers,
        requireAuth: true,
      );

      if (response == null || response is! Map<String, dynamic>) {
        return [];
      }

      return response["results"] ?? response["buyer_offers"] ?? response["data"] ?? [];
    } catch (e) {
      print("⚠️ Pending Offers API Error: $e");
      return [];
    }
  }

  /// ============================================================
  /// GET PREVIOUS OFFERS
  /// ============================================================
  static Future<List<dynamic>> getPreviousOffers() async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerPreviousOffers,
        requireAuth: true,
      );

      if (response == null || response is! Map<String, dynamic>) {
        return [];
      }

      return response["results"] ?? response["buyer_offers"] ?? response["data"] ?? [];
    } catch (e) {
      print("⚠️ Previous Offers API Error: $e");
      return [];
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

  /// ============================================================
  /// GET DELIVERY CHALLANS
  /// ============================================================
  static Future<List<dynamic>> getDeliveryChallans() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerDeliveryChallans,
      requireAuth: true,
    );

    if (response == null) {
      throw Exception("Failed to fetch delivery challans");
    }

    if (response is Map<String, dynamic> && response.containsKey("results")) {
      return response["results"] is List ? response["results"] : [];
    }
    return response is List ? response : [];
  }

  /// ============================================================
  /// GET CHALLAN DETAILS
  /// ============================================================
  static Future<Map<String, dynamic>> getChallanDetails(int id) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerChallanDetails(id),
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    return response;
  }

  /// ============================================================
  /// MARK CHALLAN AS RECEIVED
  /// ============================================================
  static Future<void> receiveChallan(int id, String remarks) async {
    await ApiClient.post(
      endpoint: "/api/buyer/delivery-challans/$id/receive/",
      body: {"received": true, "remarks": remarks},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// CREATE BUYER OFFER (REQUIREMENT)
  /// ============================================================
  static Future<void> createOffer(Map<String, dynamic> data) async {
    await ApiClient.post(
      endpoint: ApiUrls.buyerOffersCreate,
      body: data,
      requireAuth: true,
    );
  }

  /// ============================================================
  /// GET BUYER OFFER DETAILS
  /// ============================================================
  static Future<Map<String, dynamic>> getOfferDetails(int id) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerOfferDetails(id),
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    return response;
  }

  /// ============================================================
  /// CANCEL BUYER OFFER
  /// ============================================================
  static Future<void> cancelOffer(int id) async {
    await ApiClient.post(
      endpoint: ApiUrls.buyerOfferAction(id),
      body: {"action": "buyer_cancel"},
      requireAuth: true,
    );
  }

  /// ============================================================
  /// REJECT OFFER/INTEREST
  /// ============================================================
  static Future<void> rejectOffer(int productId, int interestId, String remark) async {
    await ApiClient.post(
      endpoint: "/api/offers/$productId/reject/",
      body: {"interest_id": interestId, "remark": remark},
      requireAuth: true,
    );
  }
}
