import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showError({
    String title = "Error",
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    String cleanMessage = message
        .replaceAll("Exception: ", "")
        .replaceAll("Exception:", "")
        .trim();
    if (cleanMessage.isEmpty) cleanMessage = "An unexpected error occurred.";

    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          cleanMessage,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w400,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE53935),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCirc,
    );
  }

  static void showSuccess({
    String title = "Success",
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    String cleanMessage = message.trim();
    if (cleanMessage.isEmpty) cleanMessage = "Action completed successfully.";

    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          cleanMessage,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w400,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF2E7D32),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCirc,
    );
  }

  static void showWarning({
    String title = "Notice",
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    String cleanMessage = message.trim();

    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          cleanMessage,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w400,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFF57C00),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCirc,
    );
  }

  static void showInfo({
    String title = "Notice",
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    String cleanMessage = message.trim();

    Get.closeCurrentSnackbar();
    Get.snackbar(
      "",
      "",
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          cleanMessage,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w400,
            fontSize: 13,
            height: 1.3,
          ),
        ),
      ),
      icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 26),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E88E5),
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: duration,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCirc,
    );
  }
}
