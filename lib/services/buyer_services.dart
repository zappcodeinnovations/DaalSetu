import '../network/api_client.dart';
import '../comman/api_url.dart';

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
  /// GET BUYER OFFERS / RFQS
  /// ============================================================
  static Future<List<dynamic>> getOffers({String query = ""}) async {
    // 1. Try canonical /api/rfqs/ endpoint
    try {
      String endpoint = ApiUrls.sellerRFQs;
      if (query.isNotEmpty) {
        endpoint += "?search=$query";
      }

      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
      );

      if (response != null) {
        if (response is List) return response;
        if (response is Map<String, dynamic>) {
          if (response["results"] is List) return response["results"];
          if (response["rfqs"] is List) return response["rfqs"];
          if (response["buyer_offers"] is List) return response["buyer_offers"];
          if (response["data"] is List) return response["data"];
        }
      }
    } catch (e) {
      print("⚠️ /api/rfqs/ fetch error: $e");
    }

    // 2. Fallback to /api/buyer-offers/
    try {
      String endpoint = ApiUrls.buyerOffers;
      if (query.isNotEmpty) {
        endpoint += "?search=$query";
      }

      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
      );

      if (response != null) {
        if (response is List) return response;
        if (response is Map<String, dynamic>) {
          if (response["results"] is List) return response["results"];
          if (response["buyer_offers"] is List) return response["buyer_offers"];
          if (response["data"] is List) return response["data"];
        }
      }
    } catch (e) {
      print("⚠️ /api/buyer-offers/ fallback fetch error: $e");
    }

    return [];
  }

  /// ============================================================
  /// GET ALL OFFERS & REQUIREMENTS
  /// ============================================================
  static Future<List<dynamic>> getAllOffers({String query = ""}) async {
    final List<dynamic> allList = [];
    final Set<String> seenKeys = {};

    void addUnique(dynamic item, [String prefix = '']) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['product_id']?.toString() ?? item['rfq_id']?.toString() ?? '';
        final title = item['title']?.toString() ?? item['product_title']?.toString() ?? item['commodity']?.toString() ?? '';
        final key = "$prefix-$id-$title";
        if (id.isNotEmpty && !seenKeys.contains(key)) {
          seenKeys.add(key);
          allList.add(item);
        } else if (id.isEmpty && !seenKeys.contains(title)) {
          seenKeys.add(title);
          allList.add(item);
        }
      }
    }

    // 1. Fetch all Buyer Requirements (RFQs)
    try {
      final rfqs = await getOffers(query: query);
      for (var item in rfqs) {
        addUnique(item, 'rfq');
      }
    } catch (e) {
      print("⚠️ RFQs error in getAllOffers: $e");
    }

    // 2. Try /api/offers/list/ or /api/offers/
    try {
      String endpoint = "/api/offers/list/";
      if (query.isNotEmpty) endpoint += "?search=$query";
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
      );
      if (response != null) {
        if (response is List) {
          for (var item in response) {
            addUnique(item, 'offer');
          }
        } else if (response is Map<String, dynamic>) {
          final results = response["results"] ?? response["offers"] ?? response["data"];
          if (results is List) {
            for (var item in results) {
              addUnique(item, 'offer');
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ /api/offers/list/ error in getAllOffers: $e");
    }

    // 3. Today, Pending, Previous, and Interests feeds
    try {
      final results = await Future.wait([
        getTodayOffers().catchError((_) => <dynamic>[]),
        getPendingOffers().catchError((_) => <dynamic>[]),
        getPreviousOffers().catchError((_) => <dynamic>[]),
        getMyInterests().catchError((_) => <dynamic>[]),
      ]);
      for (var list in results) {
        for (var item in list) {
          addUnique(item, 'offer');
        }
      }
    } catch (e) {
      print("⚠️ Additional feeds fetch error in getAllOffers: $e");
    }

    return allList;
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

  /// ============================================================
  /// GET DELIVERY CHALLANS
  /// ============================================================
  static Future<Map<String, dynamic>> getDeliveryChallans({int page = 1, String query = ""}) async {
    String endpoint = "${ApiUrls.buyerDeliveryChallans}?page=$page";
    if (query.isNotEmpty) {
      endpoint += "&search=$query";
    }
    
    final response = await ApiClient.get(
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// GET DELIVERY CHALLAN DETAILS
  /// ============================================================
  static Future<Map<String, dynamic>> getDeliveryChallanDetails(int challanId) async {
    final endpoint = ApiUrls.buyerDeliveryChallanDetails(challanId);
    final response = await ApiClient.get(
      endpoint: endpoint,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// RECEIVE DELIVERY CHALLAN
  /// ============================================================
  static Future<Map<String, dynamic>> receiveDeliveryChallan(int challanId, String remarks) async {
    final endpoint = ApiUrls.buyerDeliveryChallanReceive(challanId);
    final body = {
      "received": true,
      "remarks": remarks,
    };
    final response = await ApiClient.post(
      endpoint: endpoint,
      body: body,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// OFFER ACTIONS
  /// ============================================================
  static Future<Map<String, dynamic>> approveOffer(int productId, int interestId, String remark) =>
      confirmOffer(productId, interestId, remark);

  static Future<Map<String, dynamic>> confirmOffer(int productId, int interestId, String remark) async {
    final body = {
      "interest_id": interestId,
      "decision": "approve",
      if (remark.isNotEmpty) "admin_remark": remark,
      if (remark.isNotEmpty) "remark": remark,
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

  static Future<Map<String, dynamic>> rejectInterest(int productId, int interestId, String remark) async {
    final body = {
      "interest_id": interestId,
      "decision": "reject",
      if (remark.isNotEmpty) "admin_remark": remark,
      if (remark.isNotEmpty) "remark": remark,
    };

    final response = await ApiClient.post(
      endpoint: ApiUrls.offerConfirmDeal(productId),
      body: body,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to reject interest");
    }

    return response;
  }

  static Future<Map<String, dynamic>> rejectOffer(int productId, int interestId, String remark) =>
      rejectInterest(productId, interestId, remark);

  static Future<Map<String, dynamic>> showInterest(
    int productId, {
    required dynamic requestedAmount,
    required dynamic requestedQuantity,
    String remark = "",
  }) async {
    final body = {
      "offer_price": requestedAmount.toString(),
      "required_quantity": requestedQuantity.toString(),
      "requested_amount": requestedAmount.toString(),
      "requested_quantity": requestedQuantity.toString(),
      if (remark.isNotEmpty) "condition": remark,
      if (remark.isNotEmpty) "remark": remark,
    };

    final response = await ApiClient.post(
      endpoint: ApiUrls.buyerShowInterest(productId),
      body: body,
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) throw Exception("Invalid response");
    return response;
  }

  static Future<Map<String, dynamic>> sendNegotiationMessage(
    int productId,
    int interestId, {
    required String message,
    dynamic counterAmount,
    dynamic counterQuantity,
  }) async {
    final body = <String, dynamic>{
      "message": message,
    };
    if (counterAmount != null && counterAmount.toString().trim().isNotEmpty) {
      body["counter_price"] = counterAmount.toString().trim();
    }
    if (counterQuantity != null && counterQuantity.toString().trim().isNotEmpty) {
      body["counter_quantity"] = counterQuantity.toString().trim();
    }

    final response = await ApiClient.post(
      endpoint: ApiUrls.offerNegotiationMessage(productId, interestId),
      body: body,
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to send message");
    }

    return response;
  }

  static Future<Map<String, dynamic>> requestKycApproval() async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.kycRequestApproval,
      body: {},
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) throw Exception("Invalid response");
    return response;
  }

  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> body) async {
    dynamic lastError;
    // 1. Primary canonical endpoint: /api/rfqs/create/
    try {
      final response = await ApiClient.post(
        endpoint: "/api/rfqs/create/",
        body: body,
        requireAuth: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
    } catch (e) {
      lastError = e;
      print("Trying /api/buyer-requirements/ fallback: $e");
    }

    // 2. Fallback: /api/buyer-requirements/
    try {
      final response = await ApiClient.post(
        endpoint: "/api/buyer-requirements/",
        body: body,
        requireAuth: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
    } catch (e) {
      lastError = e;
      print("Buyer requirements endpoint failed: $e");
    }

    throw Exception(lastError?.toString().replaceAll("Exception: ", "") ?? "Failed to post requirement");
  }

  static Future<Map<String, dynamic>> getOfferDetails(int id) async {
    try {
      final response = await ApiClient.get(
        endpoint: "/api/rfqs/$id/",
        requireAuth: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
    } catch (e) {
      print("⚠️ /api/rfqs/$id/ fetch error: $e");
    }

    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerOfferDetails(id),
      requireAuth: true,
    );
    if (response != null && response is Map<String, dynamic>) {
      return response;
    }
    throw Exception("Invalid response format");
  }

  static Future<Map<String, dynamic>> cancelOffer(int id) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.buyerOfferAction(id),
      body: {"action": "cancel"},
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }
    return response;
  }

  static Future<Map<String, dynamic>> getChallanDetails(int challanId) => getDeliveryChallanDetails(challanId);

  static Future<Map<String, dynamic>> receiveChallan(int challanId, String remarks) => receiveDeliveryChallan(challanId, remarks);
}
