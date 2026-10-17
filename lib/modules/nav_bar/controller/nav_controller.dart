import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../utils/app_preferences.dart';

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  var userRole = ''.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      isLoading.value = true;
      final role = await AppPreferences.getRole();
      if (role != null) {
        userRole.value = role;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void changeIndex(int index) {
    debugPrint("Changing to index: $index");
    if (selectedIndex.value == index) {
      selectedIndex.refresh();
    } else {
      selectedIndex.value = index;
    }
  }
}
