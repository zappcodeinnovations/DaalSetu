import '../comman/api_url.dart';
import '../modules/profile/model/profile_model.dart';

import '../network/api_client.dart';

class ProfileService {
  static Future<ProfileModel> getProfile({bool silent = true}) async {
    final Map<String, dynamic> combined = {};

    // 1. Query base user endpoint (/api/user/)
    try {
      final userResponse = await ApiClient.get(
        endpoint: ApiUrls.profile,
        requireAuth: true,
        suppressErrorDialog: silent,
      );
      if (userResponse is Map<String, dynamic>) {
        if (userResponse['body'] is Map<String, dynamic>) {
          combined.addAll(userResponse['body'] as Map<String, dynamic>);
        } else if (userResponse['data'] is Map<String, dynamic>) {
          combined.addAll(userResponse['data'] as Map<String, dynamic>);
        } else {
          combined.addAll(userResponse);
        }
      }
    } catch (_) {}

    // 2. Query detailed profile endpoint (/api/profile/update/) which contains dob, gender, kyc documents, etc.
    try {
      final profileResponse = await ApiClient.get(
        endpoint: ApiUrls.profileUpdate,
        requireAuth: true,
        suppressErrorDialog: silent,
      );
      if (profileResponse is Map<String, dynamic>) {
        Map<String, dynamic> pData = profileResponse;
        if (pData['body'] is Map<String, dynamic>) {
          pData = pData['body'] as Map<String, dynamic>;
        }
        if (pData['data'] is Map<String, dynamic>) {
          pData = pData['data'] as Map<String, dynamic>;
        }
        pData.forEach((key, val) {
          if (val != null &&
              val.toString() != 'null' &&
              val.toString().trim().isNotEmpty) {
            combined[key] = val;
          }
        });
      }
    } catch (_) {}

    if (combined.isEmpty) {
      throw Exception("Invalid profile response");
    }

    return ProfileModel.fromJson(combined);
  }

  static Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiClient.patch(
      endpoint: ApiUrls.profileUpdate,
      data: data,
      requireAuth: true,
    );

    try {
      final refreshed = await getProfile();
      final targetDob = data['dob']?.toString().trim();
      if (targetDob != null && targetDob.isNotEmpty && (refreshed.dob.isEmpty || refreshed.dob == 'null')) {
        return refreshed.copyWith(dob: targetDob);
      }
      return refreshed;
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

    dynamic patchResponse;
    if (documentFiles.isNotEmpty) {
      patchResponse = await ApiClient.postMultipart(
        endpoint: ApiUrls.profileUpdate,
        fields: fields,
        files: documentFiles,
        requireAuth: true,
        method: 'PATCH',
      );
    } else if (fields.isNotEmpty) {
      patchResponse = await ApiClient.patch(
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

    try {
      final refreshed = await getProfile();
      final targetDob = fields['dob']?.toString().trim();
      if (targetDob != null && targetDob.isNotEmpty && (refreshed.dob.isEmpty || refreshed.dob == 'null')) {
        return refreshed.copyWith(dob: targetDob);
      }
      return refreshed;
    } catch (_) {
      if (patchResponse is Map<String, dynamic>) {
        return ProfileModel.fromJson(patchResponse);
      }
      throw Exception("Failed to update profile");
    }
  }
}
