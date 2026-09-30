import 'package:agro_broker/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:agro_broker/routes/app_routes.dart';
import 'package:agro_broker/utils/app_preferences.dart';
import 'package:get/get.dart';

import 'drawer_menu_service.dart';

class DrawerMenuRepository {
  final DrawerMenuService _service;

  DrawerMenuRepository(this._service);

  List<DrawerMenuSection>? _cachedMenu;

  Future<List<DrawerMenuSection>> getMenu() async {
    final token = await AppPreferences.getAccessToken();
    if (token == null || token.isEmpty) {
      Get.offAllNamed(AppRoutes.login);
      throw Exception("Unauthorized");
    }

    if (_cachedMenu != null) {
      return _cachedMenu!;
    }

    try {
      final menu = await _service.fetchMenu();
      _cachedMenu = menu;
      return menu;
    } catch (e) {
      if (e.toString().contains("401") || e.toString().contains("403")) {
        await AppPreferences.logout();
        Get.offAllNamed(AppRoutes.login);
      }
      rethrow;
    }
  }

  void clearCache() {
    _cachedMenu = null;
  }
}
