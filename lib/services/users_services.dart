import '../comman/api_url.dart';
import '../modules/users/model/user_model.dart';
import '../network/api_client.dart';

class UserService {
  // ── List all users ───────────────────────────────────────────────────────
  static Future<List<UserModel>> getUsers() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.users,
      requireAuth: true,
    );

    if (response == null || response is! List) {
      throw Exception('Invalid users response');
    }

    return response.map<UserModel>((e) => UserModel.fromJson(e)).toList();
  }

  // ── Get single user ──────────────────────────────────────────────────────
  static Future<UserModel> getUserById(int userId) async {
    final response = await ApiClient.get(
      endpoint: '/api/users/$userId/',
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception('Invalid user response');
    }

    return UserModel.fromJson(response);
  }

  // ── Create user ──────────────────────────────────────────────────────────
  // POST /api/users/create/
  static Future<Map<String, dynamic>> createUser(
      Map<String, dynamic> data) async {
    return await ApiClient.post(
      endpoint: '/api/users/create/',
      body: data,
      requireAuth: true,
    );
  }

  // ── Delete user ──────────────────────────────────────────────────────────
  // POST /api/users/{id}/delete/  (POST works, DELETE returns 404)
  static Future<Map<String, dynamic>> deleteUser(int userId) async {
    return await ApiClient.post(
      endpoint: '/api/users/$userId/delete/',
      body: {},
      requireAuth: true,
    );
  }

  // ── Update user (fields: first_name, last_name, mobile, email, etc.) ─────
  // PATCH /api/users/{id}/update/
  static Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> data) async {
    return await ApiClient.patch(
      endpoint: '/api/users/$userId/update/',
      data: data,
      requireAuth: true,
    );
  }

  // ── Update user account status ────────────────────────────────────────────
  // PATCH /api/users/{id}/status/  body: {status, reason}
  static Future<Map<String, dynamic>> updateUserStatus(
      int userId, String status, String reason) async {
    return await ApiClient.patch(
      endpoint: '/api/users/$userId/status/',
      data: {'status': status, 'reason': reason},
      requireAuth: true,
    );
  }
}
