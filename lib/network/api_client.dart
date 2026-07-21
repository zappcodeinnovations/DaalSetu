import 'dart:convert';
import 'dart:io';
import 'package:agro_broker/utils/global_error_handler.dart';
import 'package:http/http.dart' as http;
import 'package:agro_broker/comman/api_url.dart';
import 'package:agro_broker/utils/app_preferences.dart';
import 'dart:async';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 30);

  /// ===============================
  /// MULTIPART POST REQUEST
  /// ===============================
  static Future<Map<String, dynamic>> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    Map<String, String>? files,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);

      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(await _buildHeaders(requireAuth));

      // Add form fields
      request.fields.addAll(fields);

      // Add files
      if (files != null) {
        for (var entry in files.entries) {
          if (entry.value.isNotEmpty) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value),
            );
          }
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);

      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      print("❌ API FAILED (GET): $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on HttpException {
      throw Exception("Server Error");
    } on FormatException {
      throw Exception("Invalid Response Format");
    } 
    catch (e) {
      throw Exception("Unexpected Error: $e");
    }
  }

  /// ===============================
  /// PATCH REQUEST
  /// ===============================
  static Future<Map<String, dynamic>> patch({
    required String endpoint,
    required Map<String, dynamic> data,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);

      print("🔗 API CALL (PATCH): $endpoint");
      print("📤 BODY: $data");

      final response = await http
          .patch(
            uri,
            headers: await _buildHeaders(requireAuth),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE: ${response.body}");

      return _handleResponse(response);
    } on SocketException {
      print("❌ API FAILED (GET): $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    }
  }

  /// ===============================
  /// DELETE REQUEST
  /// ===============================
  static Future<Map<String, dynamic>> delete({
    required String endpoint,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);

      print("🔗 API CALL (DELETE): $endpoint");

      final response = await http
          .delete(uri, headers: await _buildHeaders(requireAuth))
          .timeout(_timeout);

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE: ${response.body}");

      return _handleResponse(response);
    } on SocketException {
      print("❌ API FAILED (GET): $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    }
  }

  /// ===============================
  /// NORMAL POST REQUEST (JSON)
  /// ===============================
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);
      print("🔗 API CALL (POST): $endpoint");
      print("📤 BODY: $body");

      final response = await http
          .post(
            uri,
            headers: await _buildHeaders(requireAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE: ${response.body}");

      return _handleResponse(response);
    } on SocketException {
      print("❌ API FAILED (GET): $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  /// ===============================
  /// GET REQUEST
  /// ===============================
  static Future<dynamic> get({
    required String endpoint,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);
      print("🔗 API CALL (GET): $endpoint");

      final response = await http
          .get(uri, headers: await _buildHeaders(requireAuth))
          .timeout(_timeout);

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE: ${response.body}");

      return _handleResponse(response);
    } on SocketException {
      print("❌ API FAILED (GET): $endpoint");

      GlobalErrorHandler.showNoInternet();

      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");

      GlobalErrorHandler.showServerError();

      throw Exception("Server Timeout");
    } catch (e) {
      print("❌ API FAILED (GET): $endpoint");
      print("⚠️ ERROR: $e");

      GlobalErrorHandler.showServerError();

      throw Exception("Error: $e");
    }
  }

  /// ===============================
  /// BUILD HEADERS
  /// ===============================
  static Future<Map<String, String>> _buildHeaders(bool requireAuth) async {
    Map<String, String> headers = {"Content-Type": "application/json"};

    if (requireAuth) {
      final token = await AppPreferences.getAccessToken();

      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    return headers;
  }

  /// ===============================
  /// HANDLE RESPONSE
  /// ===============================
  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      print("❌ API RESPONSE ERROR");
      print("📥 STATUS CODE: $statusCode");
      print("📥 BODY: ${response.body}");

      if (statusCode == 400) {
        throw Exception("Bad Request: ${response.body}");
      } else if (statusCode == 401) {
        throw Exception("Unauthorized");
      } else if (statusCode == 403) {
        throw Exception("Forbidden");
      } else if (statusCode == 404) {
        throw Exception("Not Found");
      } else if (statusCode >= 500) {
        throw Exception("Server Error: ${response.body}");
      } else {
        throw Exception("Unexpected Error: ${response.body}");
      }
    }
  }
}
