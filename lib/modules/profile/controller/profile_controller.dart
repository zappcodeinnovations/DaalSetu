import '../../../services/profile_services.dart';
import 'package:get/get.dart';
import '../model/profile_model.dart';

class ProfileController extends GetxController {

  var isLoading = true.obs;
  var profile = Rxn<ProfileModel>();

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
      Get.snackbar("Success", "Profile updated successfully");
      return true;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
