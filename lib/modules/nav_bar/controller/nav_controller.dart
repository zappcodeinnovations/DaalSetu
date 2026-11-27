import 'package:daalsetu/utils/kyc_lock.dart';
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
    // KYC pending: a dashboard button / KPI card cannot switch to a locked tab either.
    if (KycLock.tabLocked(userRole.value, index)) {
      final context = Get.context;
      if (context != null) KycLock.explain(context);
      return;
    }
    if (selectedIndex.value == index) {
      selectedIndex.refresh();
    } else {
      selectedIndex.value = index;
    }
  }
}
