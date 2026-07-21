import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPreferences {
  AppPreferences._();

  /// ===============================
  /// KEYS
  /// ===============================
  static const _onboardingKey = "onboarding_completed";

  static const _accessTokenKey = "access_token";
  static const _refreshTokenKey = "refresh_token";
  static const _roleKey = "user_role";
  static const _userIdKey = "user_id";
  static const _usernameKey = "username";

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  /// ===============================
  /// ONBOARDING
  /// ===============================
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// ===============================
  /// SAVE LOGIN DATA
  /// ===============================
  static Future<void> saveLoginData({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
    required String username,
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(key: _roleKey, value: role);
    await _secureStorage.write(key: _userIdKey, value: userId);
    await _secureStorage.write(key: _usernameKey, value: username);
  }

  /// ===============================
  /// GET ACCESS TOKEN
  /// ===============================
  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// ===============================
  /// GET REFRESH TOKEN
  /// ===============================
  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// ===============================
  /// GET ROLE
  /// ===============================
  static Future<String?> getRole() async {
    return await _secureStorage.read(key: _roleKey);
  }

  /// ===============================
  /// GET USER ID
  /// ===============================
  static Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// ===============================
  /// GET USERNAME
  /// ===============================
  static Future<String?> getUsername() async {
    return await _secureStorage.read(key: _usernameKey);
  }

  /// ===============================
  /// CHECK IF LOGGED IN
  /// ===============================
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// ===============================
  /// LOGOUT (Clear Only Auth Data)
  /// ===============================
  static Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _roleKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _usernameKey);
  }

  /// ===============================
  /// CLEAR ALL (Full Reset)
  /// ===============================
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}
