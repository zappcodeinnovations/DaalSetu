import '../../../services/profile_services.dart';
import '../../../comman/api_url.dart';
import 'package:get/get.dart';
import '../model/profile_model.dart';

class ProfileController extends GetxController {
  var isLoading = true.obs;
  var profile = Rxn<ProfileModel>();
  var imageRevision = DateTime.now().millisecondsSinceEpoch.obs;

  String profileImageUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final absolute = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : '${ApiUrls.baseUrl}${raw.startsWith('/') ? '' : '/'}$raw';
    final uri = Uri.parse(absolute);
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'v': '${imageRevision.value}',
          },
        )
        .toString();
  }

  @override
  void onInit() {
    fetchProfile();
    super.onInit();
  }

  var isUpdating = false.obs;

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;

      final data = await ProfileService.getProfile();
      profile.value = data;
      imageRevision.value = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      isUpdating.value = true;
      final updatedData = await ProfileService.updateProfile(data);
      profile.value = updatedData;
      imageRevision.value = DateTime.now().millisecondsSinceEpoch;
      Get.snackbar("Success", "Profile updated successfully");
      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateProfileWithFiles({
    required Map<String, String> fields,
    required Map<String, String> files,
  }) async {
    try {
      isUpdating.value = true;
      profile.value = await ProfileService.updateProfileMultipart(
        fields: fields,
        files: files,
      );
      imageRevision.value = DateTime.now().millisecondsSinceEpoch;
      Get.snackbar("Success", "Profile updated successfully");
      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
