import 'package:daalsetu/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:get/get.dart';

import '../repository/drawer_menu_repository.dart';
import '../repository/drawer_menu_service.dart';

class DrawerController extends GetxController {
  late final DrawerMenuRepository repository;

  DrawerController() {
    repository = DrawerMenuRepository(DrawerMenuService());
  }

  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;
  var menuSections = <DrawerMenuSection>[].obs;

  var mastersExpanded = true.obs;
  var offersExpanded = true.obs;

  var userRole = ''.obs;

  /// AppPreferences.sessionVersion the role/menu were loaded for; a mismatch
  /// means someone else signed in since (show a spinner, then reload).
  int loadedSession = -1;

  bool get isStale => loadedSession != AppPreferences.sessionVersion;

  @override
  void onInit() {
    super.onInit();
    _loadRoleAndMenu();
  }

  Future<void> _loadRoleAndMenu() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      loadedSession = AppPreferences.sessionVersion;
      menuSections.clear();

      final role = await AppPreferences.getRole() ?? 'buyer';
      userRole.value = role.toLowerCase();

      final isAdmin = const ['super_admin', 'admin', 'sub_admin']
          .contains(userRole.value);
      if (isAdmin) {
        final sections = await repository.getMenu();
        menuSections.assignAll(sections);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleMasters() {
    mastersExpanded.value = !mastersExpanded.value;
  }

  void toggleOffers() {
    offersExpanded.value = !offersExpanded.value;
  }

  void refreshMenu() {
    repository.clearCache();
    _loadRoleAndMenu();
  }

  void handleNavigation(String route) {
    if (Get.currentRoute != route) {
      Get.toNamed(route);
    }
  }
}
