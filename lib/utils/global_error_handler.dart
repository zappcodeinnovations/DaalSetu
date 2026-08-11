import 'package:iconly/iconly.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GlobalErrorHandler {
  /// SERVER ERROR
  static void showServerError() {
    Get.dialog(
      _buildErrorDialog(
        icon: IconlyLight.danger,
        iconColor: Colors.red,
        title: "Server Not Responding",
        message:
            "We sincerely apologize from the Daal Setu team.\n\nOur server is currently not responding. Please try again in a few moments.",
      ),
      barrierDismissible: false,
    );
  }

  /// NO INTERNET
  static void showNoInternet() {
    Get.dialog(
      _buildErrorDialog(
        icon: IconlyLight.danger,
        iconColor: Colors.orange,
        title: "No Internet Connection",
        message:
            "Please check your internet connection and try again.\n\nIf the problem continues, try reconnecting to your network.",
      ),
      barrierDismissible: false,
    );
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
