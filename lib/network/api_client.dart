import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../comman/api_url.dart';
import '../utils/app_preferences.dart';
import '../utils/global_error_handler.dart';

/// An error safe to show directly in the UI.
///
/// `Exception.toString()` prefixes messages with "Exception:", which used to
/// leak backend-style errors into snackbars throughout the app. API failures
/// now use this type so every panel receives one clean message.
class ApiRequestException implements Exception {
  const ApiRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
    } on SocketException catch (e) {
      // The reason (e.g. "Failed host lookup", "Network is unreachable") tells offline from DNS problems.
      print("❌ NO INTERNET: $endpoint ($e)");
      GlobalErrorHandler.showNoInternet();
      throw const ApiRequestException(
        "No internet connection. Please try again.",
      );
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw const ApiRequestException(
        "The server took too long to respond. Please try again.",
      );
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
    } on SocketException catch (e) {
      // The reason (e.g. "Failed host lookup", "Network is unreachable") tells offline from DNS problems.
      print("❌ NO INTERNET: $endpoint ($e)");
      GlobalErrorHandler.showNoInternet();
      throw const ApiRequestException(
        "No internet connection. Please try again.",
      );
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw const ApiRequestException(
        "The server took too long to respond. Please try again.",
      );
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
    } on SocketException catch (e) {
      // The reason (e.g. "Failed host lookup", "Network is unreachable") tells offline from DNS problems.
      print("❌ NO INTERNET: $endpoint ($e)");
      GlobalErrorHandler.showNoInternet();
      throw const ApiRequestException(
        "No internet connection. Please try again.",
      );
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw const ApiRequestException(
        "The server took too long to respond. Please try again.",
      );
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
    } on SocketException catch (e) {
      // The reason (e.g. "Failed host lookup", "Network is unreachable") tells offline from DNS problems.
      print("❌ NO INTERNET: $endpoint ($e)");
      GlobalErrorHandler.showNoInternet();
      throw const ApiRequestException(
        "No internet connection. Please try again.",
      );
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      GlobalErrorHandler.showServerError();
      throw const ApiRequestException(
        "The server took too long to respond. Please try again.",
      );
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
    } on SocketException catch (e) {
      // The reason (e.g. "Failed host lookup", "Network is unreachable") tells offline from DNS problems.
      print("❌ NO INTERNET: $endpoint ($e)");
      if (!suppressErrorDialog) GlobalErrorHandler.showNoInternet();
      throw const ApiRequestException(
        "No internet connection. Please try again.",
      );
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      if (!suppressErrorDialog) GlobalErrorHandler.showServerError();
      throw const ApiRequestException(
        "The server took too long to respond. Please try again.",
      );
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
    } on SocketException catch (e) {
      // The reason (e.g. "Failed host lookup", "Network is unreachable") tells offline from DNS problems.
      print("❌ NO INTERNET: $endpoint ($e)");
      if (!suppressErrorDialog) GlobalErrorHandler.showNoInternet();
      throw const ApiRequestException(
        "No internet connection. Please try again.",
      );
    } on TimeoutException {
      print("⏳ API TIMEOUT: $endpoint");
      if (!suppressErrorDialog) GlobalErrorHandler.showServerError();
      throw const ApiRequestException(
        "The server took too long to respond. Please try again.",
      );
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
        throw const ApiRequestException("Please sign in again to continue.");
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
      if (body.trim().isEmpty)
        return <String, dynamic>{
          "success": true,
          "message": "Action successful",
        };
      try {
        return jsonDecode(body);
      } catch (_) {
        return <String, dynamic>{
          "success": true,
          "message": "Action successful",
        };
      }
    } else {
      print("❌ API RESPONSE ERROR");
      print("📥 STATUS CODE: $statusCode");
      print("📥 RESPONSE BODY: $body");

      String errorMessage = "Something went wrong. Please try again.";
      if (body.trim().startsWith("<") ||
          body.contains("<!doctype") ||
          body.contains("<html")) {
        errorMessage =
            "Server is temporarily unavailable (HTML response). Please try again later.";
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
                  messages.add(
                    _fieldErrorMessage(key.toString(), val.join(', ')),
                  );
                } else {
                  messages.add(
                    _fieldErrorMessage(key.toString(), val.toString()),
                  );
                }
              });
            } else if (decoded['detail'] is String &&
                decoded['detail'].toString().trim().isNotEmpty) {
              messages.add(decoded['detail']);
            } else if (decoded['error'] is String &&
                decoded['error'].toString().trim().isNotEmpty) {
              messages.add(decoded['error']);
            } else if (decoded['message'] is String &&
                decoded['message'].toString().trim().isNotEmpty) {
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
                  messages.add(
                    _fieldErrorMessage(key.toString(), val.join(', ')),
                  );
                } else if (val is String && val.trim().isNotEmpty) {
                  messages.add(_fieldErrorMessage(key.toString(), val));
                } else if (val is Map) {
                  val.forEach(
                    (k, v) => messages.add(
                      _fieldErrorMessage('$key.$k', v.toString()),
                    ),
                  );
                }
              });
            }

            if (messages.isNotEmpty) {
              errorMessage = userFriendlyErrorMessage(messages.join('\n'));
            }
          } else if (decoded is List) {
            errorMessage = decoded.join('\n');
          } else if (decoded is String && decoded.trim().isNotEmpty) {
            errorMessage = userFriendlyErrorMessage(decoded);
          }
        } catch (_) {
          if (statusCode >= 500) {
            errorMessage =
                "The server is temporarily unavailable. Please try again later.";
          }
        }
      }

      if (statusCode >= 500) {
        if (!suppressErrorDialog) GlobalErrorHandler.showServerError();
        throw ApiRequestException(userFriendlyErrorMessage(errorMessage));
      } else if (statusCode == 400) {
        throw ApiRequestException(userFriendlyErrorMessage(errorMessage));
      } else if (statusCode == 401) {
        throw ApiRequestException(
          userFriendlyErrorMessage(
            errorMessage.isNotEmpty &&
                    errorMessage != "Something went wrong. Please try again."
                ? errorMessage
                : "Please sign in again to continue.",
          ),
        );
      } else if (statusCode == 403) {
        throw ApiRequestException(
          userFriendlyErrorMessage(
            errorMessage.isNotEmpty &&
                    errorMessage != "Something went wrong. Please try again."
                ? errorMessage
                : "You do not have permission to perform this action.",
          ),
        );
      } else if (statusCode == 404) {
        throw ApiRequestException(
          userFriendlyErrorMessage(
            errorMessage.isNotEmpty &&
                    errorMessage != "Something went wrong. Please try again."
                ? errorMessage
                : "The requested item was not found.",
          ),
        );
      } else {
        throw ApiRequestException(userFriendlyErrorMessage(errorMessage));
      }
    }
  }

  /// Converts common Django/DRF validation output into messages suitable for
  /// every role's snackbar or dialog. Keep this public for unit tests and for
  /// UI code that receives an error outside [ApiClient].
  static String userFriendlyErrorMessage(String message) {
    final cleaned = message
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final normalized = cleaned.toLowerCase();

    if (normalized.contains('branch') &&
        (normalized.contains('ref code') ||
            normalized.contains('reference code') ||
            normalized.contains('referral code') ||
            normalized.contains('branch_code')) &&
        (normalized.contains('invalid') ||
            normalized.contains('not found') ||
            normalized.contains('does not exist'))) {
      return 'Invalid branch reference code. Please check the code and try again.';
    }
    if (normalized.contains('branch') &&
        (normalized.contains('ref code') ||
            normalized.contains('reference code') ||
            normalized.contains('referral code') ||
            normalized.contains('branch_code')) &&
        normalized.contains('required')) {
      return 'Enter the branch reference code to continue.';
    }
    if (normalized.contains('transporter_id') &&
        normalized.contains('required')) {
      return 'Select a transporter before continuing.';
    }
    if (normalized.contains('invalid credentials')) {
      return 'The mobile number or password is incorrect.';
    }
    if (normalized.contains('html response') ||
        normalized.contains('server error') ||
        normalized.contains('internal server error')) {
      return 'The server is temporarily unavailable. Please try again later.';
    }
    if (normalized.contains('permission denied') ||
        normalized.contains('forbidden')) {
      return 'You do not have permission to perform this action.';
    }
    if (normalized.contains('not found')) {
      return 'The requested item was not found.';
    }
    return cleaned.isEmpty
        ? 'Something went wrong. Please try again.'
        : cleaned;
  }

  static String _fieldErrorMessage(String field, String detail) {
    final normalizedField = field.toLowerCase().replaceAll('-', '_');
    if (normalizedField == 'branch_code' ||
        normalizedField == 'branch_ref_code' ||
        normalizedField == 'branch_reference_code') {
      return 'Branch reference code: $detail';
    }
    if (normalizedField == 'transporter_id') {
      return 'Transporter: $detail';
    }
    if (normalizedField == 'non_field_errors' || normalizedField == 'detail') {
      return detail;
    }
    const fieldLabels = <String, String>{
      'phone': 'Mobile number',
      'mobile': 'Mobile number',
      'mobile_number': 'Mobile number',
      'phone_number': 'Mobile number',
      'email': 'Email address',
      'gst_number': 'GST number',
      'pan_number': 'PAN number',
      'aadhar_number': 'Aadhaar number',
      'aadhaar_number': 'Aadhaar number',
      'password': 'Password',
      'confirm_password': 'Confirm password',
      'quantity': 'Quantity',
      'price': 'Price',
      'branch_id': 'Branch',
      'company_id': 'Company',
      'driver_id': 'Driver',
      'vehicle_id': 'Vehicle',
    };
    final readableField =
        fieldLabels[normalizedField] ??
        field
            .replaceAll(RegExp(r'[_\.]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    return readableField.isEmpty ? detail : '$readableField: $detail';
  }
}
