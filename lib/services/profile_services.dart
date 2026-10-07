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

  static Future<ProfileModel> updateProfileMultipart({
    required Map<String, String> fields,
    required Map<String, String> files,
  }) async {
    final profileImagePath = files['profile_image'];
    final documentFiles = Map<String, String>.from(files)
      ..remove('profile_image');

    if (documentFiles.isNotEmpty) {
      await ApiClient.postMultipart(
        endpoint: ApiUrls.profileUpdate,
        fields: fields,
        files: documentFiles,
        requireAuth: true,
        method: 'PATCH',
      );
    } else if (fields.isNotEmpty) {
      await ApiClient.patch(
        endpoint: ApiUrls.profileUpdate,
        data: fields,
        requireAuth: true,
      );
    }

    if (profileImagePath != null && profileImagePath.isNotEmpty) {
      await ApiClient.postMultipart(
        endpoint: ApiUrls.profileImageUpload,
        fields: const {},
        files: {'profile_image': profileImagePath},
        requireAuth: true,
      );
    }
    return getProfile();
  }
}
