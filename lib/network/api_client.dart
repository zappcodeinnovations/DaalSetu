import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../comman/api_url.dart';
import '../utils/app_preferences.dart';
import '../utils/global_error_handler.dart';

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
    String method = 'POST', // 'PATCH' for edits that also upload a file
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);
      print("🔗 API CALL (MULTIPART $method): $endpoint");
      print("📤 FIELDS: $fields");
      print("📤 FILES: $files");

      final request = http.MultipartRequest(method, uri);

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
      print("❌ NO INTERNET: $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw Exception("Server Timeout. Please try again.");
    } catch (e) {
      rethrow;
    }
  }

  /// ===============================
  /// PUT REQUEST
  /// ===============================
  static Future<Map<String, dynamic>> put({
    required String endpoint,
    required Map<String, dynamic> data,
    bool requireAuth = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);

      print("🔗 API CALL (PUT): $endpoint");
      print("📤 BODY: $data");

      final response = await http
          .put(
            uri,
            headers: await _buildHeaders(requireAuth),
            body: jsonEncode(data),
          )
          .timeout(_timeout);

      print("📥 STATUS CODE: ${response.statusCode}");
      print("📥 RESPONSE: ${response.body}");

      return _handleResponse(response);
    } on SocketException {
      print("❌ NO INTERNET: $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw Exception("Server Timeout. Please try again.");
    } catch (e) {
      rethrow;
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

      return _handleResponse(response);
    } on SocketException {
      print("❌ NO INTERNET: $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw Exception("Server Timeout. Please try again.");
    } catch (e) {
      rethrow;
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

      return _handleResponse(response);
    } on SocketException {
      print("❌ NO INTERNET: $endpoint");
      GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw Exception("Server Timeout. Please try again.");
    } catch (e) {
      rethrow;
    }
  }

  /// ===============================
  /// NORMAL POST REQUEST (JSON)
  /// ===============================
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    bool requireAuth = false,
    bool suppressErrorDialog = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);
      print("🔗 API CALL (POST): $endpoint");

      final response = await http
          .post(
            uri,
            headers: await _buildHeaders(requireAuth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      print("📥 STATUS CODE: ${response.statusCode}");

      return _handleResponse(
        response,
        suppressErrorDialog: suppressErrorDialog,
      );
    } on SocketException {
      print("❌ NO INTERNET: $endpoint");
      if (!suppressErrorDialog) GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      if (!suppressErrorDialog) GlobalErrorHandler.showServerError();
      throw Exception("Server Timeout. Please try again.");
    } catch (e) {
      rethrow;
    }
  }

  /// ===============================
  /// GET REQUEST
  /// ===============================
  static Future<dynamic> get({
    required String endpoint,
    bool requireAuth = false,
    bool suppressErrorDialog = false,
  }) async {
    try {
      final uri = Uri.parse(ApiUrls.baseUrl + endpoint);
      print("🔗 API CALL (GET): $endpoint");

      final response = await http
          .get(uri, headers: await _buildHeaders(requireAuth))
          .timeout(_timeout);

      print("📥 STATUS CODE: ${response.statusCode}");

      return _handleResponse(
        response,
        suppressErrorDialog: suppressErrorDialog,
      );
    } on SocketException {
      print("❌ NO INTERNET: $endpoint");
      if (!suppressErrorDialog) GlobalErrorHandler.showNoInternet();
      throw Exception("No Internet Connection");
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      if (!suppressErrorDialog) GlobalErrorHandler.showServerError();
      throw Exception("Server Timeout. Please try again.");
    } catch (e) {
      print("❌ API FAILED (GET): $endpoint");
      print("⚠️ ERROR: $e");
      rethrow;
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
      } else {
        throw Exception("Unauthorized: No access token found");
      }
    }

    return headers;
  }

  /// ===============================
  /// HANDLE RESPONSE
  /// ===============================
  static dynamic _handleResponse(
    http.Response response, {
    bool suppressErrorDialog = false,
  }) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 400) {
      if (body.trim().isEmpty) return <String, dynamic>{"success": true, "message": "Action successful"};
      try {
        return jsonDecode(body);
      } catch (_) {
        return <String, dynamic>{"success": true, "message": "Action successful"};
      }
    } else {
      print("❌ API RESPONSE ERROR");
      print("📥 STATUS CODE: $statusCode");
      print("📥 RESPONSE BODY: $body");

      String errorMessage = "Something went wrong. Please try again.";
      if (body.trim().startsWith("<") || body.contains("<!doctype") || body.contains("<html")) {
        errorMessage = "Server is temporarily unavailable (HTML response). Please try again later.";
      } else {
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            final messages = <String>[];

            Map? errSource;
            if (decoded['errors'] is Map) {
              errSource = decoded['errors'] as Map;
            } else if (decoded['error'] is Map) {
              errSource = decoded['error'] as Map;
            }

            if (errSource != null) {
              errSource.forEach((key, val) {
                if (val is List) {
                  messages.add("$key: ${val.join(', ')}");
                } else {
                  messages.add("$key: $val");
                }
              });
            } else if (decoded['detail'] is String && decoded['detail'].toString().trim().isNotEmpty) {
              messages.add(decoded['detail']);
            } else if (decoded['error'] is String && decoded['error'].toString().trim().isNotEmpty) {
              messages.add(decoded['error']);
            } else if (decoded['message'] is String && decoded['message'].toString().trim().isNotEmpty) {
              messages.add(decoded['message']);
            } else {
              decoded.forEach((key, val) {
                if (key == 'status' ||
                    key == 'statusCode' ||
                    key == 'status_code' ||
                    key == 'environment' ||
                    key == 'tested_at' ||
                    key == 'http_status' ||
                    key == 'success') {
                  return;
                }

                if (val is List) {
                  messages.add("$key: ${val.join(', ')}");
                } else if (val is String && val.trim().isNotEmpty) {
                  messages.add("$key: $val");
                } else if (val is Map) {
                  val.forEach((k, v) => messages.add("$key.$k: $v"));
                }
              });
            }

            if (messages.isNotEmpty) {
              errorMessage = messages.join('\n');
            }
          } else if (decoded is List) {
            errorMessage = decoded.join('\n');
          } else if (decoded is String && decoded.trim().isNotEmpty) {
            errorMessage = decoded;
          }
        } catch (_) {
          if (statusCode >= 500) {
            errorMessage = "Server error ($statusCode). Please try again later.";
          }
        }
      }

      if (statusCode >= 500) {
        if (!suppressErrorDialog) GlobalErrorHandler.showServerError();
        throw Exception(errorMessage);
      } else if (statusCode == 400) {
        throw Exception(errorMessage);
      } else if (statusCode == 401) {
        throw Exception(errorMessage.isNotEmpty && errorMessage != "Something went wrong. Please try again." ? errorMessage : "Unauthorized (401)");
      } else if (statusCode == 403) {
        throw Exception(errorMessage.isNotEmpty && errorMessage != "Something went wrong. Please try again." ? errorMessage : "Forbidden (403)");
      } else if (statusCode == 404) {
        throw Exception(errorMessage.isNotEmpty && errorMessage != "Something went wrong. Please try again." ? errorMessage : "Resource not found (404)");
      } else {
        throw Exception(errorMessage);
      }
    }
  }
}
