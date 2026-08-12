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
}
