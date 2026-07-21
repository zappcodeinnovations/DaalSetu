import 'package:agro_broker/services/profile_services.dart';
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
  
}
