import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// KYC not approved (server flag `kyc_locked`, same rule as the web sidebar): only Dashboard, Company and
/// Branch stay open; Masters, Offers, Deals ... show a lock and explain why instead of opening.
class KycLock {
  KycLock._();

  static const String message =
      'This section unlocks after your KYC is approved. Until then you can update your company and branch details.';

  /// Menu keys that stay open while KYC is pending.
  static const Set<String> openKeys = {
    'dashboard',
    'company',
    'registered_company',
    'branches',
    'settings',
    'downloads',
    'switch_panel',
    'logout',
  };

  static bool get active {
    if (!Get.isRegistered<ProfileController>()) return false;
    return Get.find<ProfileController>().profile.value?.kycLocked ?? false;
  }

  static bool locks(String key) => active && !openKeys.contains(key);

  static Future<void> explain(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('kyc-lock-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFE65100)),
        title: const Text('KYC approval pending'),
        content: const Text(message),
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
        ],
      ),
    );
  }
}
