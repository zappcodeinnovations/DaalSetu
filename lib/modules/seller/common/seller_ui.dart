import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

/// Small shared pieces for the seller screens, matching the existing seller look.
class SellerUi {
  static const Color primary = Color(0xFFFFB300);

  static String errorText(Object error) => error.toString().replaceFirst('Exception: ', '');

  static void success(String message) {
    Get.snackbar("Success", message,
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
  }

  static void error(Object error) {
    Get.snackbar("Error", errorText(error),
        snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
  }

  /// Runs [task] behind a blocking progress dialog and reports the server message.
  static Future<Map<String, dynamic>?> run(Future<Map<String, dynamic>> Function() task, {String? successMessage}) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: primary)), barrierDismissible: false);
    try {
      final result = await task();
      if (Get.isDialogOpen ?? false) Get.back();
      success(successMessage ?? result['message']?.toString() ?? "Done");
      return result;
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      error(e);
      return null;
    }
  }

  static Future<bool> confirm(String title, String message, {String confirmText = "Yes", Color color = primary}) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () => Get.back(result: true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Asks for an optional (or required) remark; returns null when cancelled.
  static Future<String?> askText(String title, {String label = "Remark (optional)", bool required = false, String confirmText = "Submit", Color color = primary}) async {
    final controller = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              if (required && controller.text.trim().isEmpty) {
                error("$label is required.");
                return;
              }
              Get.back(result: controller.text.trim());
            },
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result;
  }

  static Color statusColor(String status) {
    final value = status.toLowerCase();
    if (value.contains('reject') || value.contains('cancel') || value.contains('expired') || value.contains('closed')) {
      return Colors.red;
    }
    if (value.contains('confirm') || value.contains('accept') || value.contains('deliver') ||
        value.contains('fulfil') || value.contains('received') || value == 'active' || value == 'ready') {
      return Colors.green;
    }
    if (value.contains('dispatch') || value.contains('negotiat') || value.contains('pending_buyer')) return Colors.blue;
    return Colors.orange;
  }

  static Widget statusChip(String status) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  static Widget emptyState(String message, {IconData icon = IconlyLight.document}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Center(child: Text(message, style: GoogleFonts.poppins(color: Colors.grey.shade600))),
      ],
    );
  }

  static Widget infoRow(String label, String? value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Expanded(
            flex: 3,
            child: Text(
              (value == null || value.isEmpty || value == 'null') ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  static Widget section(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  static AppBar appBar(BuildContext context, String title, {List<Widget>? actions}) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
      actions: actions,
    );
  }

  /// "2026-10-05T19:23:00+05:30" -> "05-10-2026 07:23 PM"; anything unparsable is shown as-is.
  static String date(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    String two(int n) => n.toString().padLeft(2, '0');
    final hasTime = value.toString().contains('T') || value.toString().contains(' ');
    final day = "${two(local.day)}-${two(local.month)}-${local.year}";
    return hasTime ? "$day ${two(hour)}:${two(local.minute)} ${local.hour >= 12 ? 'PM' : 'AM'}" : day;
  }
}
