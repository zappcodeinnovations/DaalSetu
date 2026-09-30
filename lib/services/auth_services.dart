import '../comman/api_url.dart';
import '../modules/Auth/forgot_password/model/forgot_password_model.dart';
import '../modules/Auth/login/model/login_model.dart';
import '../modules/Auth/register/model/register_model.dart';
import '../network/api_client.dart';
import '../utils/app_preferences.dart';

class AuthService {
  /// ============================================================
  /// REGISTER USER (MULTIPART)
  /// ============================================================
  static Future<String> register({
    required Map<String, String> fields,
    required Map<String, String> files,
  }) async {
    final response = await ApiClient.postMultipart(
      endpoint: ApiUrls.register,
      fields: fields,
      files: files,
      requireAuth: false,
    );

    if (response["status"] == "success") {
      return response["message"] ?? "Registration successful";
    } else {
      throw Exception(response["message"] ?? "Registration Failed");
    }
  }

  /// ============================================================
  /// LOGIN USER
  /// ============================================================
  static Future<LoginResponse> login({
    required String mobile,
    required String password,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.login,
      body: {"mobile": mobile, "password": password},
      requireAuth: false,
    );

    if (response.containsKey("access") &&
        response.containsKey("refresh") &&
        response["user"] is Map<String, dynamic>) {
      return LoginResponse.fromJson(response);
    } else {
      throw Exception(
        response["message"] ?? response["detail"] ?? "Login failed",
      );
    }
  }

  /// ============================================================
  /// CHANGE PASSWORD
  /// ============================================================
  static Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.changePassword,
      body: {
        "old_password": oldPassword,
        "new_password": newPassword,
        "confirm_password": confirmPassword,
      },
      requireAuth: true,
    );

    if (response.containsKey("message")) {
      return response["message"];
    } else {
      throw Exception(response["message"] ?? "Password Change Failed");
    }
  }

  /// ============================================================
  /// FORGOT PASSWORD
  /// ============================================================
  static Future<ForgotPasswordResponseModel> forgotPassword({
    required ForgotPasswordRequestModel request,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.forgotPassword,
      body: request.toJson(),
      requireAuth: false,
    );

    if (response.containsKey("message")) {
      return ForgotPasswordResponseModel.fromJson(response);
    } else {
      throw Exception(response["message"] ?? "Something went wrong");
    }
  }

  /// ============================================================
  /// REFRESH ACCESS TOKEN
  /// ============================================================
  static Future<String?> refreshAccessToken() async {
    final refreshToken = await AppPreferences.getRefreshToken();

    if (refreshToken == null) return null;

    final response = await ApiClient.post(
      endpoint: ApiUrls.refresh,
      body: {"refresh": refreshToken},
      requireAuth: false,
    );

    if (response.containsKey("access")) {
      final newAccess = response["access"];

      await AppPreferences.saveLoginData(
        accessToken: newAccess,
        refreshToken: refreshToken,
        role: await AppPreferences.getRole() ?? "",
        userId: await AppPreferences.getUserId() ?? "",
        username: await AppPreferences.getUsername() ?? "",
      );

      return newAccess;
    } else {
      await logout();
      return null;
    }
  }

  /// ============================================================
  /// VERIFY OTP
  /// ============================================================
  static Future<bool> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.verifyOtp,
      body: {"mobile": mobile, "otp": otp},
      requireAuth: false,
    );

    if (response["status"] == "success") {
      return true;
    } else {
      throw Exception(response["message"] ?? "OTP Verification Failed");
    }
  }

  /// ============================================================
  /// LOGOUT
  /// ============================================================
  static Future<void> logout() async {
    await AppPreferences.logout();
  }
}
