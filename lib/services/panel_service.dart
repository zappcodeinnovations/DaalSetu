import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/nav_bar/controller/nav_controller.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:get/get.dart';

/// Buyer & Seller accounts: choose the panel after login and switch panels
/// without logging out. The server keeps the active panel and answers every
/// API as that single role; in the app every role check reads the panel
/// through [AppPreferences.getRole].
class PanelService {
  static const buyer = 'buyer';
  static const seller = 'seller';

  static String label(String panel) => panel == buyer ? 'Buyer' : 'Seller';
  static String other(String panel) => panel == buyer ? seller : buyer;

  /// Tells the server, stores the panel locally and reopens the app in it.
  static Future<void> activate(String panel) async {
    final response = await ApiClient.post(
      endpoint: ApiUrls.activePanel,
      body: {'panel': panel},
      requireAuth: true,
    );
    if (response is Map && response['success'] == false) {
      throw Exception(response['message'] ?? 'Could not switch the panel.');
    }
    await AppPreferences.setActivePanel(panel);
    // Role-bound controllers are rebuilt for the new panel; the side drawer
    // reloads its menu on the new session version.
    AppPreferences.sessionVersion++;
    if (Get.isRegistered<BottomNavController>()) {
      Get.delete<BottomNavController>(force: true);
    }
    Get.offAllNamed(AppRoutes.mainNav);
  }

  /// Switches to the other panel.
  static Future<void> switchPanel() async {
    final current = await AppPreferences.getActivePanel();
    final panel = (current == null || current.isEmpty) ? AppPreferences.defaultPanel : current;
    await activate(other(panel));
  }
}
