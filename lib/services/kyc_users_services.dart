import 'package:agro_broker/modules/kyc_users/model/kyc_user_model.dart';
import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/comman/api_url.dart';

class KycService {
  /// Fetch KYC Users
  static Future<List<KycUserModel>> fetchKycUsers() async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.kycUsers, // /api/kyc/users/
      requireAuth: true,
    );

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
