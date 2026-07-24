import 'package:get/get.dart';
import 'package:agro_broker/utils/app_preferences.dart';

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  var userRole = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AppPreferences.getRole();
    if (role != null) {
      userRole.value = role;
    }
  }

  void changeIndex(int index) {
    print("Changing to index: $index");
    selectedIndex.value = index;
  }
}
