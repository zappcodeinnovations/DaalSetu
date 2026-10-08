import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../comman/api_url.dart';
import '../../../utils/app_preferences.dart';
import '../model/branch_report_model.dart';

class AdminReportsService {
  static const String _cacheKey = "admin_reports_cache_v1";
  static const Duration _timeout = Duration(seconds: 15);

  /// ── Build Authenticated Headers ─────────────────────────────────────────
  static Future<Map<String, String>> _buildHeaders() async {
    final token = await AppPreferences.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  /// ── Save To Local Storage (SharedPreferences) ───────────────────────────
  static Future<void> _saveToStorage(List<BranchReportModel> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(reports.map((r) => r.toJson()).toList());
      await prefs.setString(_cacheKey, jsonStr);
      debugPrint("💾 [ADMIN REPORTS STORAGE] Cached ${reports.length} reports to local storage.");
    } catch (e) {
      debugPrint("⚠️ [ADMIN REPORTS STORAGE] Failed to cache reports: $e");
    }
  }

  /// ── Load From Local Storage ─────────────────────────────────────────────
  static Future<List<BranchReportModel>> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          final list = decoded
              .map((item) => BranchReportModel.fromJson(item is Map<String, dynamic> ? item : {}))
              .toList();
          debugPrint("💾 [ADMIN REPORTS STORAGE] Loaded ${list.length} reports from local storage.");
          return list;
        }
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN REPORTS STORAGE] Error reading local storage: $e");
    }
    return [];
  }

  /// ============================================================
  /// FETCH BRANCH PERFORMANCE REPORTS
  /// Uses S.No 21 (GET /api/admin/dashboard/) where branch_performance is provided.
  /// Falls back to the last real report saved on this device.
  /// ============================================================
  static Future<List<BranchReportModel>> getBranchReports() async {
    final headers = await _buildHeaders();
    final url = Uri.parse("${ApiUrls.baseUrl}${ApiUrls.adminDashboard}");

    debugPrint("📊 [ADMIN REPORTS API] Requesting branch report data from: $url");

    String? serverError;
    try {
      final res = await http.get(url, headers: headers).timeout(_timeout);
      debugPrint("📊 [ADMIN REPORTS API] Response Status Code: ${res.statusCode}");
      debugPrint("📊 [ADMIN REPORTS API] Response Body Preview: ${res.body.length > 300 ? '${res.body.substring(0, 300)}...' : res.body}");

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('branch_performance')) {
          final rawList = decoded['branch_performance'] as List;
          final reports = rawList
              .map((item) => BranchReportModel.fromJson(item is Map<String, dynamic> ? item : {}))
              .toList();

          debugPrint("✅ [ADMIN REPORTS API] Parsed ${reports.length} branch reports from live server.");
          await _saveToStorage(reports);
          return reports;
        }
      } else {
        serverError = res.statusCode == 403
            ? 'Only Admin or Super Admin can view branch reports.'
            : 'Could not load branch reports (${res.statusCode}).';
      }
    } catch (e) {
      debugPrint("⚠️ [ADMIN REPORTS API] Server request note: $e. Checking local storage cache...");
    }

    // Check Local Storage Cache
    final cached = await _loadFromStorage();
    if (cached.isNotEmpty) {
      debugPrint("✅ [ADMIN REPORTS STORAGE] Returning ${cached.length} cached branch reports.");
      return cached;
    }

    // No sample numbers: an empty or failed report must not look like real branch data.
    throw Exception(serverError ?? 'Could not load branch reports. Pull down to try again.');
  }
}
