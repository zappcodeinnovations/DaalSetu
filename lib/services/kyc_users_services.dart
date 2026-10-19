import '../modules/kyc_users/model/kyc_user_model.dart';
import '../network/api_client.dart';
import '../comman/api_url.dart';

class KycService {
  /// Fetch KYC Users
  static Future<List<KycUserModel>> fetchKycUsers({
    String? search,
    String? role,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      queryParams['role'] = role.toLowerCase();
    }
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
    }

    final uri = Uri(
      path: ApiUrls.kycUsers,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await ApiClient.get(
      endpoint: uri.toString(),
      requireAuth: true,
    );

    print("=== KYC USERS API RESPONSE ===");
    print(response);
    print("==============================");

    final List results = response['results'] ?? [];

    return results.map((e) => KycUserModel.fromJson(e)).toList();
  }

  /// Approve KYC
  static Future<void> approveKyc(int id) async {
    await ApiClient.post(
      endpoint: "/api/kyc/$id/approve/",
      requireAuth: true,
      body: {},
    );
  }

  /// Reject KYC
  static Future<void> rejectKyc(int id, String reason) async {
    await ApiClient.post(
      endpoint: "/api/kyc/$id/reject/",
      requireAuth: true,
      body: {"rejection_reason": reason},
    );
  }
}
