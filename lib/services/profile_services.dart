import '../comman/api_url.dart';
import '../modules/profile/model/profile_model.dart';

import '../network/api_client.dart';

class ProfileService {

  static Future<ProfileModel> getProfile() async {

    final response = await ApiClient.get(
      endpoint: ApiUrls.profile, // "/api/user/"
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid profile response");
    }

    return ProfileModel.fromJson(response);
  }

  static Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiClient.patch(
      endpoint: ApiUrls.profileUpdate,
      data: data,
      requireAuth: true,
    );

    // Re-fetch the complete user profile to ensure fields like role and account_status remain intact
    try {
      return await getProfile();
    } catch (_) {
      return ProfileModel.fromJson(response);
    }
  }
}
