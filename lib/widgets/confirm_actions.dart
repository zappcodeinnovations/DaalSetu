import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dialog buttons in the app-wide order: the primary action first (left), Cancel second (right).
/// Use as `Get.defaultDialog(actions: confirmActions(...))`. `Get.defaultDialog` itself always
/// puts Cancel first, so its own confirm / cancel parameters must not be used.
List<Widget> confirmActions({
  required String confirmText,
  required VoidCallback onConfirm,
  String cancelText = 'CANCEL',
  Color? color,
  VoidCallback? onCancel,
}) {
  final primary = color ?? Get.theme.colorScheme.primary;
  final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.light
      ? Colors.black87
      : Colors.white;
  // One row, both buttons exactly the same size (the width of the longer label), same height.
  return [
    IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: onPrimary,
                minimumSize: const Size(96, 46),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel ?? () => Get.back(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(96, 46),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(cancelText),
            ),
          ),
        ],
      ),
    ),
  ];
}
