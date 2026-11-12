import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalErrorHandler {
  static bool _isShowingDialog = false;

  /// Network errors are expected while the screen is off and for a moment after
  /// unlocking (Android cuts background network), so no popup in those windows.
  static bool get _appCanShowNetworkError {
    AppForeground.ensureTracking();
    return AppForeground.isActive && AppForeground.secondsSinceResume >= 5;
  }

  /// SERVER ERROR
  static void showServerError() {
    if (_isShowingDialog || !_appCanShowNetworkError) return;
    _isShowingDialog = true;
    Get.dialog(
      _buildErrorDialog(
        icon: IconlyLight.danger,
        iconColor: Colors.red,
        title: "Server Not Responding",
        message:
            "We sincerely apologize from the Daal Setu team.\n\nOur server is currently not responding. Please try again in a few moments.",
      ),
      barrierDismissible: true,
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// NO INTERNET
  static void showNoInternet() {
    if (_isShowingDialog || !_appCanShowNetworkError) return;
    _isShowingDialog = true;
    Get.dialog(
      _buildErrorDialog(
        icon: IconlyLight.danger,
        iconColor: Colors.orange,
        title: "No Internet Connection",
        message:
            "Please check your internet connection and try again.\n\nIf the problem continues, try reconnecting to your network.",
      ),
      barrierDismissible: true,
    ).then((_) {
      _isShowingDialog = false;
    });
  }

  /// COMMON MODERN DIALOG UI
  static Widget _buildErrorDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ICON
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: iconColor,
              ),
            ),

            const SizedBox(height: 18),

            /// TITLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// MESSAGE
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 22),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Get.back();
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether the app is on screen, and how long since it came back from background.
class AppForeground with WidgetsBindingObserver {
  AppForeground._();

  static final AppForeground _instance = AppForeground._();
  static bool _tracking = false;
  static DateTime? _resumedAt;

  /// Call once at startup; also called lazily by the helpers below.
  static void ensureTracking() {
    if (_tracking) return;
    _tracking = true;
    WidgetsBinding.instance.addObserver(_instance);
  }

  /// True while the app is visible and in the foreground (screen on, not minimised).
  static bool get isActive {
    ensureTracking();
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  static int get secondsSinceResume =>
      _resumedAt == null ? 1 << 30 : DateTime.now().difference(_resumedAt!).inSeconds;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _resumedAt = DateTime.now();
  }
}
