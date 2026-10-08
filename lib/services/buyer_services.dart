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

    // 1. Fetch all Seller Products (Offers)
    try {
      String endpoint = ApiUrls.products;
      if (query.isNotEmpty) endpoint += "?search=$query";
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final products = _extractList(response);
      for (var item in products) {
        addUnique(item, 'product');
      }
    } catch (e) {
      print("⚠️ Products error in getAllOffers: $e");
    }

    // 2. Fetch all Buyer Requirements (RFQs)
    try {
      final rfqs = await getOffers(query: query);
      for (var item in rfqs) {
        addUnique(item, 'rfq');
      }
    } catch (e) {
      print("⚠️ RFQs error in getAllOffers: $e");
    }

    // 3. Try /api/offers/list/
    try {
      String endpoint = "/api/offers/list/";
      if (query.isNotEmpty) endpoint += "?search=$query";
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      for (var item in list) {
        addUnique(item, 'offer');
      }
    } catch (e) {
      print("⚠️ /api/offers/list/ error in getAllOffers: $e");
    }

    return allList;
  }

  static bool _isToday(dynamic dateStr) {
    if (dateStr == null) return false;
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) {
      final str = dateStr.toString();
      final now = DateTime.now();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      return str.contains("$y-$m-$d");
    }
  }

  static List<dynamic> _extractList(dynamic response) {
    if (response == null) return [];
    if (response is List) return response;
    if (response is Map) {
      if (response['results'] is List) return response['results'] as List;
      if (response['data'] is List) return response['data'] as List;
      if (response['offers'] is List) return response['offers'] as List;
      if (response['buyer_offers'] is List) return response['buyer_offers'] as List;
      if (response['interests'] is List) return response['interests'] as List;
      if (response['my_interests'] is List) return response['my_interests'] as List;
      if (response['items'] is List) return response['items'] as List;
      if (response['products'] is List) return response['products'] as List;
      if (response['rfqs'] is List) return response['rfqs'] as List;
      if (response['body'] is List) return response['body'] as List;
    }
    return [];
  }

  /// ============================================================
  /// GET TODAY'S OFFERS
  /// ============================================================
  static Future<List<dynamic>> getTodayOffers() async {
    final List<dynamic> todayList = [];
    final Set<String> seenKeys = {};

    void addUnique(dynamic item) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['product_id']?.toString() ?? item['rfq_id']?.toString() ?? '';
        final title = item['title']?.toString() ?? item['product_title']?.toString() ?? item['commodity']?.toString() ?? '';
        final key = "$id-$title";
        if (id.isNotEmpty && !seenKeys.contains(key)) {
          seenKeys.add(key);
          todayList.add(item);
        }
      }
    }

    // 1. Primary server endpoint
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerTodayOffers,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      for (var item in list) {
        addUnique(item);
      }
    } catch (e) {
      print("⚠️ /api/offers/today/ fetch error: $e");
    }

    // 2. If endpoint returned empty, check products created today only
    if (todayList.isEmpty) {
      try {
        final response = await ApiClient.get(
          endpoint: ApiUrls.products,
          requireAuth: true,
          suppressErrorDialog: true,
        );
        final list = _extractList(response);
        for (var item in list) {
          if (item is Map) {
            final created = item['created_at'] ?? item['updated_at'] ?? item['created'];
            if (_isToday(created)) {
              addUnique(item);
            }
          }
        }
      } catch (_) {}
    }

    return todayList;
  }

  /// ============================================================
  /// GET PENDING OFFERS
  /// ============================================================
  static Future<List<dynamic>> getPendingOffers() async {
    final List<dynamic> pendingList = [];
    final Set<String> seenKeys = {};

    void addUnique(dynamic item) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['product_id']?.toString() ?? item['interest_id']?.toString() ?? item['rfq_id']?.toString() ?? '';
        final title = item['title']?.toString() ?? item['product_title']?.toString() ?? item['commodity']?.toString() ?? '';
        final key = "$id-$title";
        if (id.isNotEmpty && !seenKeys.contains(key)) {
          seenKeys.add(key);
          pendingList.add(item);
        }
      }
    }

    // 1. Primary: Fetch active pending buyer interests & negotiations (deals awaiting confirmation / in negotiation)
    try {
      final interests = await getMyInterests();
      for (var item in interests) {
        if (item is Map) {
          final s = (item['status'] ?? item['deal_status'] ?? '').toString().toLowerCase();
          if (s == 'interested' ||
              s == 'negotiation' ||
              s == 'pending' ||
              s == 'buyer_confirmed' ||
              s == 'seller_confirmed' ||
              s.contains('pending') ||
              s.contains('negotiat')) {
            addUnique(item);
          }
        }
      }
    } catch (_) {}

    // 2. Also check pending endpoint
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerPendingOffers,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      for (var item in list) {
        addUnique(item);
      }
    } catch (e) {
      print("⚠️ Pending offers fetch error: $e");
    }

    // 3. Fallback check for buyer-offers with pending status
    try {
      final response = await ApiClient.get(
        endpoint: "${ApiUrls.buyerOffers}?status=pending",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      for (var item in list) {
        addUnique(item);
      }
    } catch (_) {}

    return pendingList;
  }

  /// ============================================================
  /// GET PREVIOUS OFFERS
  /// ============================================================
  static Future<List<dynamic>> getPreviousOffers() async {
    final List<dynamic> previousList = [];
    final Set<String> seenKeys = {};

    void addUnique(dynamic item) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['product_id']?.toString() ?? item['interest_id']?.toString() ?? item['rfq_id']?.toString() ?? '';
        final title = item['title']?.toString() ?? item['product_title']?.toString() ?? item['commodity']?.toString() ?? '';
        final key = "$id-$title";
        if (id.isNotEmpty && !seenKeys.contains(key)) {
          seenKeys.add(key);
          previousList.add(item);
        }
      }
    }

    // 1. Primary server endpoint for previous listings (loads previous days' offers from server)
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerPreviousOffers,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      for (var item in list) {
        addUnique(item);
      }
    } catch (e) {
      print("⚠️ Previous offers fetch error: $e");
    }

    // 2. Fallback check for buyer-offers with previous status
    try {
      final response = await ApiClient.get(
        endpoint: "${ApiUrls.buyerOffers}?status=previous",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      for (var item in list) {
        addUnique(item);
      }
    } catch (_) {}

    // 3. Fallback check for completed, closed, rejected or expired buyer deals
    try {
      final interests = await getMyInterests();
      for (var item in interests) {
        if (item is Map) {
          final s = (item['status'] ?? item['deal_status'] ?? '').toString().toLowerCase();
          if (s == 'deal_confirmed' ||
              s == 'closed' ||
              s == 'rejected' ||
              s == 'expired' ||
              s == 'completed' ||
              s == 'cancelled' ||
              s.contains('confirm') ||
              s.contains('reject') ||
              s.contains('close') ||
              s.contains('expire') ||
              s.contains('cancel')) {
            addUnique(item);
          }
        }
      }
    } catch (_) {}

    return previousList;
  }

  /// ============================================================
  /// GET MY INTERESTS
  /// ============================================================
  static Future<List<dynamic>> getMyInterests() async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerMyInterests,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      return _extractList(response);
    } catch (e) {
      print("⚠️ /api/offers/my-interests/list/ fetch error: $e");
      return [];
    }
  }

  /// ============================================================
  /// GET DELIVERY CHALLANS
  /// ============================================================
  static Future<Map<String, dynamic>> getDeliveryChallans({int page = 1, String query = "", String status = ""}) async {
    String endpoint = "${ApiUrls.buyerDeliveryChallans}?page=$page";
    if (query.isNotEmpty) {
      endpoint += "&search=${Uri.encodeComponent(query)}";
    }
    if (status.isNotEmpty && status.toLowerCase() != "all" && status.toLowerCase() != "all statuses") {
      endpoint += "&status=${status.toLowerCase()}";
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
    // 1. Try canonical /api/rfqs/$id/ (Buyer Requirements)
    try {
      final response = await ApiClient.get(
        endpoint: "/api/rfqs/$id/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        if (response['rfq'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['rfq']);
        }
        if (response['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['data']);
        }
        return response;
      }
    } catch (_) {}

    // 2. Try /api/offers/$id/
    try {
      final response = await ApiClient.get(
        endpoint: "/api/offers/$id/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        if (response['offer'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['offer']);
        }
        if (response['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['data']);
        }
        return response;
      }
    } catch (_) {}

    // 3. Try /api/buyer-offers/$id/
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.buyerOfferDetails(id),
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        if (response['buyer_offer'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['buyer_offer']);
        }
        if (response['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['data']);
        }
        return response;
      }
    } catch (_) {}

    // 4. Try /api/products/$id/
    try {
      final response = await ApiClient.get(
        endpoint: "${ApiUrls.products}$id/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        if (response['product'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['product']);
        }
        if (response['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response['data']);
        }
        return response;
      }
    } catch (_) {}

    throw Exception("Offer / Requirement details not found");
  }

  static Future<Map<String, dynamic>> cancelOffer(int id) async {
    try {
      final response = await ApiClient.post(
        endpoint: "/api/rfqs/$id/cancel/",
        body: {},
        requireAuth: true,
        suppressErrorDialog: true,
      );
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
    } catch (_) {}

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
