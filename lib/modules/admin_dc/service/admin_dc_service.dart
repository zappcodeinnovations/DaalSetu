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

    // 1. Build Query Parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
        'status': status.toLowerCase(),
      if (search != null && search.trim().isNotEmpty)
        'search': search.trim(),
    };

    // 2. Attempt Admin Endpoint
    final adminUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDeliveryChallans}")
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    debugPrint("📦 [ADMIN DC API] Fetching from: $adminUrl");

    try {
      final res = await http.get(adminUrl, headers: headers).timeout(_timeout);
      debugPrint("📦 [ADMIN DC API] Admin Endpoint HTTP Status: ${res.statusCode}");
      debugPrint("📦 [ADMIN DC API] Admin Endpoint Response Body: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        serverChallans = _parseChallansList(decoded);
        debugPrint("✅ [ADMIN DC API] Successfully retrieved ${serverChallans.length} challans from Admin endpoint.");
      } else {
        debugPrint("⚠️ [ADMIN DC API] Admin endpoint returned ${res.statusCode}. Trying fallback seller endpoint...");
        final sellerUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.sellerDeliveryChallans}");
        final fallbackRes = await http.get(sellerUrl, headers: headers).timeout(_timeout);
        if (fallbackRes.statusCode >= 200 && fallbackRes.statusCode < 300) {
          final decoded = jsonDecode(fallbackRes.body);
          serverChallans = _parseChallansList(decoded);
          debugPrint("✅ [ADMIN DC API] Retrieved ${serverChallans.length} challans from fallback endpoint.");
        }
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Server request note: $e");
    }

    // 3. Clear any legacy local mock entries so data is 100% dependent on backend
    await clearLocalChallans();

    debugPrint("📦 [ADMIN DC API] Returning ${serverChallans.length} live challans from backend.");
    return serverChallans;
  }

  /// ============================================================
  /// GET SINGLE CHALLAN DETAILS (100% LIVE BACKEND)
  /// ============================================================
  static Future<Map<String, dynamic>?> getChallanDetails(int id) async {
    final headers = await _buildHeaders();

    try {
      final url = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDeliveryChallanDetails(id)}");
      debugPrint("📦 [ADMIN DC API] Fetching details from: $url");
      final res = await http.get(url, headers: headers).timeout(_timeout);
      debugPrint("📦 [ADMIN DC API] Details Response Status: ${res.statusCode}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'];
        }
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Error fetching server details: $e");
    }

    return null;
  }

  /// ============================================================
  /// CREATE DELIVERY CHALLAN
  /// Sends payload to backend developer's live endpoint.
  /// Seamlessly parses the live response or falls back to local cache.
  /// ============================================================
  static Future<Map<String, dynamic>> createDeliveryChallan(Map<String, dynamic> payload) async {
    final headers = await _buildHeaders();
    final adminUrl = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDeliveryChallans}");

    debugPrint("📦 [ADMIN DC API] Creating Delivery Challan at: $adminUrl");
    debugPrint("   Payload: ${jsonEncode(payload)}");

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
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == false) {
          final errorMsg = extractResponseMessage(res.body, fallback: "Failed to create Delivery Challan");
          return {
            "success": false,
            "message": errorMsg,
            "existing_challan_id": decoded['existing_challan_id'],
          };
        }

        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          responseData = decoded['data'];
        } else if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        }

        // Create model from server response
        final newChallan = AdminChallanModel.fromJson(responseData);
        final successMsg = extractResponseMessage(res.body, fallback: "Delivery challan created as draft.");
        debugPrint("✅ [ADMIN DC API] Live Delivery Challan #${newChallan.displayChallanNo} created on Server.");
        return {
          "success": true,
          "message": successMsg,
          "id": newChallan.id,
          "challan_number": newChallan.challanNumber,
          "server_synced": true,
          "data": responseData,
        };
      } else {
        // Server returned an error (e.g. 400 Bad Request)
        final errorMsg = extractResponseMessage(res.body, fallback: "Failed to create Delivery Challan (${res.statusCode})");
        int? existingId;
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            existingId = decoded['existing_challan_id'];
          }
        } catch (_) {}

        return {
          "success": false,
          "message": errorMsg,
          "existing_challan_id": existingId,
        };
      }
    } catch (e) {
      debugPrint("❌ [ADMIN DC API] Server POST exception: $e");
      return {
        "success": false,
        "message": "Connection error: Unable to connect to server ($e)",
      };
    }
  }

  /// ============================================================
  /// DISPATCH CHALLAN
  /// ============================================================
  static Future<Map<String, dynamic>> dispatchChallan(int id) async {
    final headers = await _buildHeaders();

    // Attempt on server
    try {
      final url = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDispatchChallan(id)}");
      debugPrint("📦 [ADMIN DC API] Dispatching Delivery Challan #$id at: $url");
      final res = await http.post(url, headers: headers, body: "{}").timeout(_timeout);
      debugPrint("📦 [ADMIN DC API] Dispatch Response Status: ${res.statusCode}");
      debugPrint("📦 [ADMIN DC API] Dispatch Response Body: ${res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final msg = extractResponseMessage(res.body, fallback: "Shipment marked as Dispatched successfully!");
        return {
          "success": true,
          "message": msg,
        };
      } else {
        final errorMsg = extractResponseMessage(res.body, fallback: "Failed to dispatch delivery challan.");
        return {
          "success": false,
          "message": errorMsg,
        };
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Server dispatch note: $e");
      return {
        "success": false,
        "message": "Connection error: Unable to dispatch delivery challan.",
      };
    }
  }

  /// ============================================================
  /// EXTRACT USER-FRIENDLY RESPONSE MESSAGE FROM BACKEND
  /// ============================================================
  static String extractResponseMessage(dynamic body, {String fallback = "Request processed."}) {
    if (body == null) return fallback;
    try {
      dynamic decoded;
      if (body is String) {
        if (body.trim().isEmpty) return fallback;
        decoded = jsonDecode(body);
      } else {
        decoded = body;
      }

      if (decoded is Map<String, dynamic>) {
        if (decoded['message'] != null && decoded['message'].toString().trim().isNotEmpty) {
          return decoded['message'].toString().trim();
        }
        if (decoded['error'] != null && decoded['error'].toString().trim().isNotEmpty) {
          return decoded['error'].toString().trim();
        }
        if (decoded['detail'] != null && decoded['detail'].toString().trim().isNotEmpty) {
          return decoded['detail'].toString().trim();
        }

        // Handle nested field validation errors (e.g. {"driver_phone": ["Enter a valid mobile number"]})
        final fieldErrors = <String>[];
        decoded.forEach((key, val) {
          if (key != 'success' && key != 'status' && key != 'code' && key != 'existing_challan_id') {
            final fieldLabel = key
                .replaceAll('_', ' ')
                .split(' ')
                .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                .join(' ');
            if (val is List && val.isNotEmpty) {
              fieldErrors.add("$fieldLabel: ${val.first}");
            } else if (val is String && val.isNotEmpty) {
              fieldErrors.add("$fieldLabel: $val");
            }
          }
        });

        if (fieldErrors.isNotEmpty) {
          return fieldErrors.join("\n");
        }
      }
    } catch (_) {}
    return fallback;
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
      } else if (response.containsKey('data')) {
        if (response['data'] is List) {
          rawList = response['data'];
        } else if (response['data'] is Map<String, dynamic>) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap.containsKey('results') && dataMap['results'] is List) {
            rawList = dataMap['results'];
          } else if (dataMap.containsKey('challans') && dataMap['challans'] is List) {
            rawList = dataMap['challans'];
          }
        }
      } else if (response.containsKey('challans') && response['challans'] is List) {
        rawList = response['challans'];
      }
    }
    return rawList
        .map((item) => AdminChallanModel.fromJson(item is Map<String, dynamic> ? item : {}))
        .toList();
  }

  // ── Helper: Cache Cleanup ────────────────────────────────────────────────
  static Future<void> clearLocalChallans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_localChallansKey)) {
        await prefs.remove(_localChallansKey);
        debugPrint("🧹 [ADMIN DC API] Cleared local cached challans.");
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN DC API] Error clearing local challans: $e");
    }
  }
}
