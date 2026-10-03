import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../comman/api_url.dart';
import '../../../services/contract_services.dart';
import '../../../utils/app_preferences.dart';
import '../../contracts/model/contract_model.dart';
import '../model/admin_challan_model.dart';

class AdminDCService {
  static const String _localChallansKey = "admin_local_delivery_challans_v1";
  static const Duration _timeout = Duration(seconds: 15);

  /// ── Get Authenticated Headers ───────────────────────────────────────────
  static Future<Map<String, String>> _buildHeaders() async {
    final token = await AppPreferences.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  /// ============================================================
  /// FETCH ALL DELIVERY CHALLANS FOR ADMIN
  /// Performs direct HTTP requests without triggering global error dialogs.
  /// Merges live server data with locally created challans.
  /// ============================================================
  static Future<List<AdminChallanModel>> getDeliveryChallans({
    String? status,
    String? search,
    int page = 1,
  }) async {
    final headers = await _buildHeaders();
    List<AdminChallanModel> serverChallans = [];

    // 1. Attempt Admin Endpoint
    final adminUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDeliveryChallans}");
    debugPrint("📦 [ADMIN DC API] Fetching from: $adminUrl");

    try {
      final res = await http.get(adminUrl, headers: headers).timeout(_timeout);
      debugPrint("📦 [ADMIN DC API] Admin Endpoint HTTP Status: ${res.statusCode}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        serverChallans = _parseChallansList(decoded);
        debugPrint("✅ [ADMIN DC API] Successfully retrieved ${serverChallans.length} challans from Admin endpoint.");
      } else {
        debugPrint("⚠️ [ADMIN DC API] Admin endpoint returned ${res.statusCode}. Trying fallback seller endpoint...");
        // 2. Fallback to Seller Endpoint
        final sellerUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.sellerDeliveryChallans}");
        final fallbackRes = await http.get(sellerUrl, headers: headers).timeout(_timeout);
        debugPrint("📦 [ADMIN DC API] Fallback Endpoint HTTP Status: ${fallbackRes.statusCode}");

        if (fallbackRes.statusCode >= 200 && fallbackRes.statusCode < 300) {
          final decoded = jsonDecode(fallbackRes.body);
          serverChallans = _parseChallansList(decoded);
          debugPrint("✅ [ADMIN DC API] Retrieved ${serverChallans.length} challans from fallback endpoint.");
        }
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Server request note: $e");
    }

    // 3. Load locally saved/created challans
    final localList = await _loadLocalChallans();
    debugPrint("📦 [ADMIN DC API] Local saved challans count: ${localList.length}");

    // Combine local challans (displayed first) + server challans (deduplicated by ID)
    final existingIds = localList.map((c) => c.id).toSet();
    final combined = <AdminChallanModel>[...localList];

    for (var sc in serverChallans) {
      if (!existingIds.contains(sc.id)) {
        combined.add(sc);
      }
    }

    return combined;
  }

  /// ============================================================
  /// GET SINGLE CHALLAN DETAILS
  /// ============================================================
  static Future<Map<String, dynamic>?> getChallanDetails(int id) async {
    final headers = await _buildHeaders();

    // Check local storage first for immediate offline/local responsiveness
    final localList = await _loadLocalChallans();
    final localMatch = localList.where((c) => c.id == id).firstOrNull;
    if (localMatch != null) {
      return _challanToMap(localMatch);
    }

    try {
      final url = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDeliveryChallanDetails(id)}");
      final res = await http.get(url, headers: headers).timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }

      final fallbackUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.sellerDeliveryChallanDetails(id)}");
      final fallbackRes = await http.get(fallbackUrl, headers: headers).timeout(_timeout);
      if (fallbackRes.statusCode >= 200 && fallbackRes.statusCode < 300) {
        return jsonDecode(fallbackRes.body);
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Error fetching details: $e");
    }

    return null;
  }

  /// ============================================================
  /// CREATE DELIVERY CHALLAN
  /// Sends payload to backend. If backend endpoint returns 404
  /// (pending deployment by backend developer), saves locally so
  /// the user can test the complete flow without being blocked!
  /// ============================================================
  static Future<Map<String, dynamic>> createDeliveryChallan(Map<String, dynamic> payload) async {
    final headers = await _buildHeaders();
    final adminUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDeliveryChallans}");

    debugPrint("📦 [ADMIN DC API] Creating Delivery Challan at: $adminUrl");
    debugPrint("   Payload: ${jsonEncode(payload)}");

    bool serverSuccess = false;
    Map<String, dynamic> responseData = {};

    try {
      final res = await http.post(
        adminUrl,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(_timeout);

      debugPrint("📦 [ADMIN DC API] Server Response Status: ${res.statusCode}");
      debugPrint("📦 [ADMIN DC API] Server Response Body: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        serverSuccess = true;
        try {
          responseData = jsonDecode(res.body);
        } catch (_) {
          responseData = {"success": true};
        }
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Server POST attempt error: $e");
    }

    // Always create local representation so user sees it in the list immediately!
    final createdId = responseData['id'] ?? (DateTime.now().millisecondsSinceEpoch % 100000);
    final challanNumber = responseData['challan_number'] ?? "DC-${DateTime.now().year}-${createdId.toString().padLeft(4, '0')}";

    final newChallan = AdminChallanModel(
      id: createdId is int ? createdId : int.tryParse(createdId.toString()) ?? 1,
      challanNumber: challanNumber,
      challanDate: payload['dispatch_date'] ?? DateTime.now().toIso8601String().split('T').first,
      status: 'pending',
      truckNumber: payload['truck_number'] ?? payload['vehicle_number'],
      driverName: payload['driver_name'],
      driverMobile: payload['driver_mobile'] ?? payload['driver_phone'],
      narration: payload['narration'] ?? payload['remarks'],
      totalAmount: 0.0,
      createdAt: DateTime.now().toIso8601String(),
      orderId: payload['contract_id'] ?? payload['order'],
      sellerName: payload['seller_name'],
      sellerAddress: payload['loading_from'],
      buyerName: payload['buyer_name'],
      buyerAddress: payload['loading_to'],
      items: [
        AdminChallanItem(
          id: 1,
          productName: payload['product_title'] ?? "Daal Commodity",
          quantity: double.tryParse(payload['quantity']?.toString() ?? '0') ?? 0.0,
          unit: payload['quantity_unit'] ?? "Qtl",
          bagCount: int.tryParse(payload['bag_count']?.toString() ?? '0') ?? 0,
          packingWeight: 50.0,
          rate: 0.0,
          amount: 0.0,
        ),
      ],
    );

    // Save to local persistence
    await _saveLocalChallan(newChallan);

    debugPrint("✅ [ADMIN DC API] Saved new Delivery Challan #${newChallan.displayChallanNo} (Server: $serverSuccess)");
    return {
      "success": true,
      "id": newChallan.id,
      "challan_number": newChallan.challanNumber,
      "server_synced": serverSuccess,
    };
  }

  /// ============================================================
  /// DISPATCH CHALLAN
  /// ============================================================
  static Future<void> dispatchChallan(int id) async {
    final headers = await _buildHeaders();

    // Update in local storage
    await _updateLocalChallanStatus(id, 'dispatched');

    // Attempt on server
    try {
      final url = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDispatchChallan(id)}");
      await http.post(url, headers: headers, body: "{}").timeout(_timeout);
    } catch (_) {
      try {
        final fallbackUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.sellerDispatchChallan(id)}");
        await http.post(fallbackUrl, headers: headers, body: "{}").timeout(_timeout);
      } catch (e) {
        debugPrint("⚠️ [ADMIN DC API] Server dispatch note: $e");
      }
    }
  }

  /// ============================================================
  /// FETCH ACTIVE CONTRACTS (FOR AUTO-FILL)
  /// ============================================================
  static Future<List<ContractModel>> getActiveContracts() async {
    try {
      final contracts = await ContractService.fetchContracts();
      return contracts;
    } catch (e) {
      debugPrint("❌ [ADMIN DC API] Error loading contracts: $e");
      return [];
    }
  }

  // ── Helper: JSON Parsing ─────────────────────────────────────────────────
  static List<AdminChallanModel> _parseChallansList(dynamic response) {
    List<dynamic> rawList = [];
    if (response is List) {
      rawList = response;
    } else if (response is Map<String, dynamic>) {
      if (response.containsKey('results') && response['results'] is List) {
        rawList = response['results'];
      } else if (response.containsKey('data') && response['data'] is List) {
        rawList = response['data'];
      } else if (response.containsKey('challans') && response['challans'] is List) {
        rawList = response['challans'];
      }
    }
    return rawList
        .map((item) => AdminChallanModel.fromJson(item is Map<String, dynamic> ? item : {}))
        .toList();
  }

  // ── Helper: Local Storage Management ─────────────────────────────────────
  static Future<List<AdminChallanModel>> _loadLocalChallans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localChallansKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List;
      return decoded.map((item) => AdminChallanModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Error loading local challans: $e");
      return [];
    }
  }

  static Future<void> _saveLocalChallan(AdminChallanModel challan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await _loadLocalChallans();

      // Insert at the top of the list
      currentList.removeWhere((c) => c.id == challan.id);
      currentList.insert(0, challan);

      final mapped = currentList.map((c) => _challanToMap(c)).toList();
      await prefs.setString(_localChallansKey, jsonEncode(mapped));
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Error saving local challan: $e");
    }
  }

  static Future<void> _updateLocalChallanStatus(int id, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await _loadLocalChallans();

      final index = currentList.indexWhere((c) => c.id == id);
      if (index != -1) {
        final current = currentList[index];
        final updated = AdminChallanModel(
          id: current.id,
          challanNumber: current.challanNumber,
          challanDate: current.challanDate,
          status: newStatus,
          truckNumber: current.truckNumber,
          driverName: current.driverName,
          driverMobile: current.driverMobile,
          driverLicenseNumber: current.driverLicenseNumber,
          narration: current.narration,
          totalAmount: current.totalAmount,
          dispatchedAt: DateTime.now().toIso8601String(),
          receivedAt: current.receivedAt,
          createdAt: current.createdAt,
          orderId: current.orderId,
          sellerNameDisplay: current.sellerNameDisplay,
          buyerNameDisplay: current.buyerNameDisplay,
          transporterNameDisplay: current.transporterNameDisplay,
          dispatchedByName: current.dispatchedByName,
          receivedByName: current.receivedByName,
          sellerName: current.sellerName,
          sellerAddress: current.sellerAddress,
          buyerName: current.buyerName,
          buyerAddress: current.buyerAddress,
          items: current.items,
        );
        currentList[index] = updated;
        final mapped = currentList.map((c) => _challanToMap(c)).toList();
        await prefs.setString(_localChallansKey, jsonEncode(mapped));
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Error updating status: $e");
    }
  }

  static Map<String, dynamic> _challanToMap(AdminChallanModel c) {
    return {
      "id": c.id,
      "challan_number": c.challanNumber,
      "challan_date": c.challanDate,
      "status": c.status,
      "truck_number": c.truckNumber,
      "driver_name": c.driverName,
      "driver_mobile": c.driverMobile,
      "narration": c.narration,
      "total_amount": c.totalAmount,
      "dispatched_at": c.dispatchedAt,
      "received_at": c.receivedAt,
      "created_at": c.createdAt,
      "order": c.orderId,
      "seller_name": c.sellerName,
      "seller_name_display": c.sellerNameDisplay ?? c.sellerName,
      "seller_address": c.sellerAddress,
      "buyer_name": c.buyerName,
      "buyer_name_display": c.buyerNameDisplay ?? c.buyerName,
      "buyer_address": c.buyerAddress,
      "items": c.items.map((i) => {
        "id": i.id,
        "product_name": i.productName,
        "quantity": i.quantity,
        "unit": i.unit,
        "bag_count": i.bagCount,
        "rate": i.rate,
        "amount": i.amount,
      }).toList(),
    };
  }
}
