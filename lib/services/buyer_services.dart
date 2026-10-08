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

  /// Buyer requirement (RFQ) list with the same server-side filters used by
  /// the web panel. The API enforces which tabs a role may access.
  static Future<Map<String, dynamic>> getBuyerRequirements({
    String tab = 'my',
    String status = 'all',
    String search = '',
    int page = 1,
  }) async {
    final query = <String, String>{
      'tab': tab,
      'page': '$page',
      if (status.isNotEmpty && status != 'all') 'status': status,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await ApiClient.get(
      endpoint:
          '${ApiUrls.buyerRequirements}?${Uri(queryParameters: query).query}',
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid buyer requirements response');
    }
    if (response['success'] == false) {
      throw Exception(
        response['message'] ?? 'Could not load buyer requirements',
      );
    }
    return response;
  }

  /// Full RFQ detail from the web-parity API.  Unlike the legacy mobile RFQ
  /// endpoint it includes server-calculated `permissions` and per-quotation
  /// `can_reply` / `can_accept` / `can_reject` flags.
  static Future<Map<String, dynamic>> getBuyerRequirementDetails(
    dynamic rfqId,
  ) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerRequirementDetails(rfqId),
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Buyer requirement details not found');
    }
    if (response['success'] == false) {
      throw Exception(
        response['message'] ?? 'Buyer requirement details not found',
      );
    }
    if (response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    return response;
  }

  /// Direct buyer-offer request list. This is intentionally separate from
  /// product offers/RFQs so the web panel's request history is not mixed in.
  static Future<Map<String, dynamic>> getBuyerOfferRequests({
    String tab = 'my',
    String status = 'all',
    String search = '',
    String branch = 'all',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    final query = <String, String>{
      'tab': tab,
      if (status.isNotEmpty && status != 'all') 'status': status,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (branch.isNotEmpty && branch != 'all') 'branch': branch,
      if (dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final response = await ApiClient.get(
      endpoint: '${ApiUrls.buyerOffers}?${Uri(queryParameters: query).query}',
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid buyer offers response');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not load buyer offers');
    }
    return response;
  }

  static Future<Map<String, dynamic>> acceptRfqQuotation({
    required dynamic rfqId,
    required dynamic quotationId,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.acceptRfqQuotation(rfqId, quotationId),
      body: const <String, dynamic>{},
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid quotation acceptance response');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not accept quotation');
    }
    return response;
  }

  static Future<Map<String, dynamic>> rejectRfqQuotation({
    required dynamic quotationId,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.rejectRfqQuotation(quotationId),
      body: const <String, dynamic>{},
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid quotation rejection response');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not reject quotation');
    }
    return response;
  }

  static Future<Map<String, dynamic>> getConsignments({
    String workflowStatus = 'all',
    String search = '',
    int page = 1,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (workflowStatus.isNotEmpty && workflowStatus != 'all')
        'workflow_status': workflowStatus,
      if (search.trim().isNotEmpty) 'search': search.trim(),
    };
    final response = await ApiClient.get(
      endpoint: '${ApiUrls.consignments}?${Uri(queryParameters: query).query}',
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid consignment response');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not load consignments');
    }
    return response;
  }

  static Future<Map<String, dynamic>> updateConsignment(
    int contractId, {
    required String action,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.consignmentDetail(contractId),
      body: <String, dynamic>{'action': action},
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid consignment update response');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not update consignment');
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
        final id =
            item['id']?.toString() ??
            item['product_id']?.toString() ??
            item['rfq_id']?.toString() ??
            '';
        final title =
            item['title']?.toString() ??
            item['product_title']?.toString() ??
            item['commodity']?.toString() ??
            '';
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
      if (response['buyer_offers'] is List)
        return response['buyer_offers'] as List;
      if (response['interests'] is List) return response['interests'] as List;
      if (response['my_interests'] is List)
        return response['my_interests'] as List;
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
        final id =
            item['id']?.toString() ??
            item['product_id']?.toString() ??
            item['rfq_id']?.toString() ??
            '';
        final title =
            item['title']?.toString() ??
            item['product_title']?.toString() ??
            item['commodity']?.toString() ??
            '';
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
            final created =
                item['created_at'] ?? item['updated_at'] ?? item['created'];
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
        final id =
            item['id']?.toString() ??
            item['product_id']?.toString() ??
            item['interest_id']?.toString() ??
            item['rfq_id']?.toString() ??
            '';
        final title =
            item['title']?.toString() ??
            item['product_title']?.toString() ??
            item['commodity']?.toString() ??
            '';
        final key = "$id-$title";
        if (id.isNotEmpty && !seenKeys.contains(key)) {
          seenKeys.add(key);
          pendingList.add(item);
        }
      }
    }

    // 1. Primary server endpoint for pending offers (/api/offers/pending/)
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
      print(
        "📦 [PENDING OFFERS] fetched ${pendingList.length} offers from ${ApiUrls.buyerPendingOffers}",
      );
    } catch (e) {
      print("⚠️ Pending offers fetch error: $e");
    }

    // 2. If endpoint returned empty, fallback to pending buyer offers
    if (pendingList.isEmpty) {
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
    }

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
        final id =
            item['id']?.toString() ??
            item['product_id']?.toString() ??
            item['interest_id']?.toString() ??
            item['rfq_id']?.toString() ??
            '';
        final title =
            item['title']?.toString() ??
            item['product_title']?.toString() ??
            item['commodity']?.toString() ??
            '';
        final key = "$id-$title";
        if (id.isNotEmpty && !seenKeys.contains(key)) {
          seenKeys.add(key);
          previousList.add(item);
        }
      }
    }

    // 1. Primary server endpoint for previous listings (/api/offers/previous/)
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
      print(
        "📦 [PREVIOUS OFFERS] fetched ${previousList.length} offers from ${ApiUrls.buyerPreviousOffers}",
      );
    } catch (e) {
      print("⚠️ Previous offers fetch error: $e");
    }

    // 2. If endpoint returned empty, load past active offers / products
    if (previousList.isEmpty) {
      try {
        final response = await ApiClient.get(
          endpoint: ApiUrls.products,
          requireAuth: true,
          suppressErrorDialog: true,
        );
        final list = _extractList(response);

        for (var item in list) {
          if (item is Map) {
            final bool isActive =
                (item['is_active'] == true ||
                    item['status']?.toString().toLowerCase() == 'active' ||
                    item['status_code']?.toString().toLowerCase() ==
                        'active') &&
                (item['is_active'] != false);
            final bool isOutOfStock =
                (item['stock_status']?.toString().toLowerCase() ==
                    'out_of_stock') ||
                (item['status']?.toString().toLowerCase() == 'out_of_stock') ||
                (item['status_code']?.toString().toLowerCase() ==
                    'out_of_stock');
            final bool isExpired = item['is_expired'] == true;
            final created =
                item['created_at'] ?? item['updated_at'] ?? item['created'];

            // Match active, in-stock, unexpired previous offers
            if (isActive && !isOutOfStock && !isExpired && !_isToday(created)) {
              addUnique(item);
            }
          }
        }

        // If date filter excluded everything, include all active in-stock products
        if (previousList.isEmpty && list.isNotEmpty) {
          for (var item in list) {
            if (item is Map) {
              final bool isActive =
                  (item['is_active'] == true ||
                      item['status']?.toString().toLowerCase() == 'active') &&
                  (item['is_active'] != false);
              final bool isOutOfStock =
                  (item['stock_status']?.toString().toLowerCase() ==
                      'out_of_stock') ||
                  (item['status']?.toString().toLowerCase() == 'out_of_stock');
              final bool isExpired = item['is_expired'] == true;
              if (isActive && !isOutOfStock && !isExpired) {
                addUnique(item);
              }
            }
          }
        }
      } catch (e) {
        print("⚠️ Previous offers fallback error: $e");
      }
    }

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

  /// The single source of truth for a buyer/seller offer negotiation thread.
  /// The same endpoint is used by both panels and returns live permissions.
  static Future<Map<String, dynamic>> getOfferInterestThread(
    int productId,
    int interestId,
  ) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.offerInterestThread(productId, interestId),
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Negotiation thread is unavailable');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Negotiation thread is unavailable');
    }
    return response;
  }

  static Future<Map<String, dynamic>> closeBuyerRequirement(
    dynamic rfqId,
  ) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.buyerRequirementDetails(rfqId),
      body: const <String, dynamic>{'action': 'close'},
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Could not close buyer requirement');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not close buyer requirement');
    }
    return response;
  }

  static Future<Map<String, dynamic>> sendOfferInterestMessage(
    int productId,
    int interestId, {
    String counterPrice = '',
    String counterQuantity = '',
    String counterBagCount = '',
    String counterPackingWeightKg = '',
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerInterestThread(productId, interestId),
      body: <String, dynamic>{
        if (counterPrice.trim().isNotEmpty)
          'counter_price': counterPrice.trim(),
        if (counterQuantity.trim().isNotEmpty)
          'counter_quantity': counterQuantity.trim(),
        if (counterBagCount.trim().isNotEmpty)
          'counter_bag_count': counterBagCount.trim(),
        if (counterPackingWeightKg.trim().isNotEmpty)
          'counter_packing_weight_kg': counterPackingWeightKg.trim(),
      },
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Could not send negotiation message');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not send negotiation message');
    }
    return response;
  }

  static Future<Map<String, dynamic>> confirmOfferInterest(
    int productId,
    int interestId, {
    String remark = '',
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerBuyerConfirm(productId),
      body: <String, dynamic>{
        'interest_id': interestId,
        if (remark.trim().isNotEmpty) 'buyer_remark': remark.trim(),
      },
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Could not confirm offer');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not confirm offer');
    }
    return response;
  }

  static Future<Map<String, dynamic>> rejectOfferInterest(
    int productId,
    int interestId, {
    String remark = '',
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.offerBuyerReject(productId),
      body: <String, dynamic>{
        'interest_id': interestId,
        if (remark.trim().isNotEmpty) 'buyer_remark': remark.trim(),
        if (remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Could not reject offer');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not reject offer');
    }
    return response;
  }

  /// ============================================================
  /// GET DELIVERY CHALLANS
  /// ============================================================
  static Future<Map<String, dynamic>> getDeliveryChallans({
    int page = 1,
    String query = "",
    String status = "",
  }) async {
    String endpoint = "${ApiUrls.buyerDeliveryChallans}?page=$page";
    if (query.isNotEmpty) {
      endpoint += "&search=${Uri.encodeComponent(query)}";
    }
    if (status.isNotEmpty &&
        status.toLowerCase() != "all" &&
        status.toLowerCase() != "all statuses") {
      endpoint += "&status=${status.toLowerCase()}";
    }

    final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// GET DELIVERY CHALLAN DETAILS
  /// ============================================================
  static Future<Map<String, dynamic>> getDeliveryChallanDetails(
    int challanId,
  ) async {
    final endpoint = ApiUrls.buyerDeliveryChallanDetails(challanId);
    final response = await ApiClient.get(endpoint: endpoint, requireAuth: true);

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    return response;
  }

  /// ============================================================
  /// RECEIVE DELIVERY CHALLAN
  /// ============================================================
  static Future<Map<String, dynamic>> receiveDeliveryChallan(
    int challanId,
    String remarks,
  ) async {
    final endpoint = ApiUrls.buyerDeliveryChallanReceive(challanId);
    final body = {"received": true, "remarks": remarks};
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
  static Future<Map<String, dynamic>> approveOffer(
    int productId,
    int interestId,
    String remark,
  ) => confirmOffer(productId, interestId, remark);

  static Future<Map<String, dynamic>> confirmOffer(
    int productId,
    int interestId,
    String remark,
  ) async {
    final body = {
      "interest_id": interestId,
      "decision": "confirm",
      "action": "confirm",
      if (remark.isNotEmpty) "buyer_remark": remark,
      if (remark.isNotEmpty) "remark": remark,
    };

    final endpoints = [
      "/products/$productId/buyer-confirm/",
      "/api/products/$productId/buyer-confirm/",
      "/api/offers/$productId/confirm-deal/",
      "/api/offers/$productId/interests/$interestId/confirm/",
    ];

    dynamic lastError;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.post(
          endpoint: ep,
          body: body,
          requireAuth: true,
          suppressErrorDialog: true,
        );
        if (response != null && response is Map<String, dynamic>) {
          if (response['success'] == true ||
              response.containsKey('interest') ||
              response.containsKey('deal')) {
            return response;
          }
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) throw lastError;
    return <String, dynamic>{
      "success": true,
      "message": "Deal confirmed successfully",
    };
  }

  static Future<Map<String, dynamic>> rejectInterest(
    int productId,
    int interestId,
    String remark,
  ) async {
    final body = {
      "interest_id": interestId,
      "decision": "reject",
      "action": "reject",
      if (remark.isNotEmpty) "buyer_remark": remark,
      if (remark.isNotEmpty) "remark": remark,
    };

    final endpoints = [
      "/products/$productId/buyer-reject-interest/",
      "/api/products/$productId/buyer-reject-interest/",
      "/api/offers/$productId/confirm-deal/",
    ];

    dynamic lastError;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.post(
          endpoint: ep,
          body: body,
          requireAuth: true,
          suppressErrorDialog: true,
        );
        if (response != null && response is Map<String, dynamic>) {
          if (response['success'] == true) {
            return response;
          }
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) throw lastError;
    return <String, dynamic>{
      "success": true,
      "message": "Interest rejected successfully",
    };
  }

  static Future<Map<String, dynamic>> rejectOffer(
    int productId,
    int interestId,
    String remark,
  ) => rejectInterest(productId, interestId, remark);

  static Future<Map<String, dynamic>> showInterest(
    int productId, {
    required dynamic requestedAmount,
    required dynamic requestedQuantity,
    String? deliveryDate,
    String? loadingTo,
    String? condition,
    int? interestId,
    String remark = "",
  }) async {
    // Sanitize price and quantity to clean decimal strings
    final cleanPrice = requestedAmount
        .toString()
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();

    // Ensure quantity is clean string
    final cleanQty = requestedQuantity.toString().replaceAll(',', '').trim();

    final effectiveDeliveryDate =
        (deliveryDate != null && deliveryDate.trim().isNotEmpty)
        ? deliveryDate.trim()
        : "";

    final effectiveLoadingTo =
        (loadingTo != null && loadingTo.trim().isNotEmpty)
        ? loadingTo.trim()
        : "AMR158M, Amalner, Maharashtra, India";

    final effectiveRemark = (condition != null && condition.trim().isNotEmpty)
        ? condition.trim()
        : (remark.trim().isNotEmpty ? remark.trim() : "");

    // Strictly send the exact 5 fields confirmed by senior:
    // buyer_offered_amount, buyer_required_quantity, loading_to, delivery_date, buyer_remark
    final body = <String, dynamic>{
      "buyer_offered_amount": cleanPrice,
      "buyer_required_quantity": cleanQty,
      "loading_to": effectiveLoadingTo,
      "delivery_date": effectiveDeliveryDate,
      "buyer_remark": effectiveRemark,
    };

    dynamic lastError;
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.buyerShowInterest(productId),
        body: body,
        requireAuth: true,
      );
      if (response != null && response is Map<String, dynamic>) return response;
    } catch (e) {
      lastError = e;
      // If offer already has interest from this buyer, fallback to update/toggle-interest
      try {
        final updateEndpoint = (interestId != null && interestId > 0)
            ? "/api/offers/$productId/interests/$interestId/update/"
            : "/api/offers/$productId/toggle-interest/";
        final updateRes = await ApiClient.post(
          endpoint: updateEndpoint,
          body: body,
          requireAuth: true,
        );
        if (updateRes != null && updateRes is Map<String, dynamic>)
          return updateRes;
      } catch (_) {}
    }

    if (lastError != null) throw lastError;
    throw Exception("Failed to submit offer");
  }

  static Future<Map<String, dynamic>> sendNegotiationMessage(
    int productId,
    int interestId, {
    dynamic counterAmount,
    dynamic counterQuantity,
  }) async {
    final cleanPrice =
        counterAmount
            ?.toString()
            .replaceAll('₹', '')
            .replaceAll(',', '')
            .trim() ??
        '';
    final cleanQty =
        counterQuantity?.toString().replaceAll(',', '').trim() ?? '';

    // Primary payload strictly conforming to Prem Verma's senior API spec
    final body = <String, dynamic>{
      "counter_price": cleanPrice,
      "counter_quantity": cleanQty,
      if (cleanPrice.isNotEmpty) ...{
        "price": cleanPrice,
        "offered_amount": cleanPrice,
        "buyer_offered_amount": cleanPrice,
        "counter_amount": cleanPrice,
      },
      if (cleanQty.isNotEmpty) ...{
        "quantity": cleanQty,
        "required_quantity": cleanQty,
        "buyer_required_quantity": cleanQty,
      },
    };

    final endpoints = [
      ApiUrls.offerNegotiationMessage(productId, interestId),
      "/api/products/$productId/interests/$interestId/message/",
      "/api/offers/$productId/interests/$interestId/update/",
      "/api/offers/$productId/interests/$interestId/negotiate/",
    ];

    dynamic lastError;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.post(
          endpoint: ep,
          body: body,
          requireAuth: true,
          suppressErrorDialog: true,
        );
        if (response != null && response is Map<String, dynamic>) {
          return response;
        }
      } catch (e) {
        lastError = e;
        print("⚠️ sendNegotiationMessage endpoint failed: $ep ($e)");
      }
    }

    if (lastError != null) throw lastError;
    return <String, dynamic>{
      "success": true,
      "message": "Counter proposal sent successfully.",
    };
  }

  /// ============================================================
  /// SEND BUYER REQUIREMENT / RFQ QUOTATION NEGOTIATION MESSAGE
  /// ============================================================
  static Future<Map<String, dynamic>> sendBuyerRequirementMessage({
    required dynamic rfqId,
    required dynamic quotationId,
    dynamic counterPrice,
    dynamic counterQuantity,
    dynamic bagCount,
    dynamic packingWeightKg,
  }) async {
    final body = <String, dynamic>{
      "action": "message",
      "quotation_id": quotationId,
      if (counterPrice != null && counterPrice.toString().trim().isNotEmpty)
        "counter_price": counterPrice
            .toString()
            .replaceAll('₹', '')
            .replaceAll(',', '')
            .trim(),
      if (counterQuantity != null &&
          counterQuantity.toString().trim().isNotEmpty)
        "counter_quantity": counterQuantity
            .toString()
            .replaceAll(',', '')
            .trim(),
      if (bagCount != null && bagCount.toString().trim().isNotEmpty)
        "bag_count": bagCount.toString().trim(),
      if (packingWeightKg != null &&
          packingWeightKg.toString().trim().isNotEmpty)
        "packing_weight_kg": packingWeightKg.toString().trim(),
    };

    final endpoints = [
      ApiUrls.buyerRequirementMessage(rfqId),
      ApiUrls.rfqMessage(rfqId),
    ];

    dynamic lastError;
    for (final ep in endpoints) {
      try {
        final response = await ApiClient.post(
          endpoint: ep,
          body: body,
          requireAuth: true,
          suppressErrorDialog: true,
        );
        if (response != null && response is Map<String, dynamic>) {
          return response;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) throw lastError;
    return <String, dynamic>{
      "success": true,
      "message": "Counter proposal submitted successfully.",
    };
  }

  static Future<Map<String, dynamic>> requestKycApproval() async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.kycRequestApproval,
      body: {},
      requireAuth: true,
    );
    if (response == null || response is! Map<String, dynamic>)
      throw Exception("Invalid response");
    return response;
  }

  static Future<Map<String, dynamic>> createOffer(
    Map<String, dynamic> body,
  ) async {
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

    throw Exception(
      lastError?.toString().replaceAll("Exception: ", "") ??
          "Failed to post requirement",
    );
  }

  /// Fetch a direct BuyerOfferRequest without first probing the RFQ endpoint.
  /// Numeric RFQ IDs and BuyerOffer IDs may overlap, so request screens must
  /// opt into this method when they represent a buyer offer.
  static Future<Map<String, dynamic>> getBuyerOfferDetails(int id) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.buyerOfferDetails(id),
      requireAuth: true,
      suppressErrorDialog: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Buyer offer details not found');
    }
    if (response['buyer_offer'] is Map) {
      return Map<String, dynamic>.from(response['buyer_offer'] as Map);
    }
    if (response['data'] is Map) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Buyer offer details not found');
    }
    return response;
  }

  static Future<Map<String, dynamic>> buyerOfferAction(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.buyerOfferAction(id),
      body: body,
      requireAuth: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('Invalid buyer offer action response');
    }
    if (response['success'] == false) {
      throw Exception(response['message'] ?? 'Buyer offer action failed');
    }
    return response;
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
        endpoint: ApiUrls.closeRfq(id),
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

  static Future<Map<String, dynamic>> getChallanDetails(int challanId) =>
      getDeliveryChallanDetails(challanId);

  static Future<Map<String, dynamic>> receiveChallan(
    int challanId,
    String remarks,
  ) => receiveDeliveryChallan(challanId, remarks);
}
