import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daalsetu/services/push_notification_service.dart';
import 'package:daalsetu/utils/app_snackbar.dart';

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
  static const _activeBranchIdKey = "active_branch_id";
  static const _activeBranchCodeKey = "active_branch_code";
  // Buyer & Seller accounts: the account's role and the panel it acts in.
  static const _accountRoleKey = "account_role";
  static const _activePanelKey = "active_panel";
  static const combinedRole = 'both_sellerandbuyer';
  static const defaultPanel = 'seller';

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  /// Bumped on every login and logout, so screens that cache per-user state (the
  /// side drawer's role menu) can tell a different session started.
  static int sessionVersion = 0;

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
    String? activeBranchId,
    String? activeBranchCode,
    String? accountRole,
    String? activePanel,
  }) async {
    sessionVersion++;
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _secureStorage.write(key: _roleKey, value: role);
    if (accountRole != null) {
      await _secureStorage.write(key: _accountRoleKey, value: accountRole);
    }
    if (activePanel != null) {
      await _secureStorage.write(key: _activePanelKey, value: activePanel);
    }
    await _secureStorage.write(key: _userIdKey, value: userId);
    await _secureStorage.write(key: _usernameKey, value: username);
    if (activeBranchId != null) {
      await _secureStorage.write(
        key: _activeBranchIdKey,
        value: activeBranchId,
      );
    }
    if (activeBranchCode != null) {
      await _secureStorage.write(
        key: _activeBranchCodeKey,
        value: activeBranchCode,
      );
    }
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
  /// The role the app acts as. A Buyer & Seller account acts as its active
  /// panel ('buyer' / 'seller'); every other account returns its own role.
  static Future<String?> getRole() async {
    final role = await _secureStorage.read(key: _roleKey);
    final account = await _secureStorage.read(key: _accountRoleKey) ?? role;
    if (account == combinedRole) {
      final panel = await _secureStorage.read(key: _activePanelKey);
      return (panel == null || panel.isEmpty) ? defaultPanel : panel;
    }
    return role;
  }

  /// The account's own role (e.g. 'both_sellerandbuyer'), never the panel.
  static Future<String?> getAccountRole() async {
    return await _secureStorage.read(key: _accountRoleKey) ??
        await _secureStorage.read(key: _roleKey);
  }

  static Future<bool> isCombinedAccount() async =>
      (await getAccountRole()) == combinedRole;

  static Future<String?> getActivePanel() async {
    return await _secureStorage.read(key: _activePanelKey);
  }

  static Future<void> setActivePanel(String panel) async {
    await _secureStorage.write(key: _activePanelKey, value: panel);
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

  static Future<String?> getActiveBranchId() =>
      _secureStorage.read(key: _activeBranchIdKey);

  static Future<String?> getActiveBranchCode() =>
      _secureStorage.read(key: _activeBranchCodeKey);

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
    // Dismiss any active session toasts/snackbars before switching to Sign In.
    AppSnackbar.dismissAll();
    // Stop push notifications for this user on this phone (needs the token, so first).
    await PushNotificationService.unregister();
    sessionVersion++;
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _roleKey);
    await _secureStorage.delete(key: _accountRoleKey);
    await _secureStorage.delete(key: _activePanelKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _usernameKey);
    await _secureStorage.delete(key: _activeBranchIdKey);
    await _secureStorage.delete(key: _activeBranchCodeKey);
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
