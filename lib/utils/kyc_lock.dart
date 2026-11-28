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

  /// Bottom tabs: Dashboard, the Menu drawer, Settings and the buyer's Branch tab stay open.
  static bool tabLocked(String role, int index) {
    if (!active) return false;
    if (role == 'seller' || role == 'both_sellerandbuyer') return index == 1 || index == 3;
    if (role == 'transporter') return index >= 1 && index <= 3;
    if (role == 'buyer' || role == 'buyer_seller' || role == 'both') return index >= 1 && index <= 3;
    return false;
  }

  /// Business screens, by route / screen name (named routes and `Get.to(() => SomeView())`, whose route is
  /// "/SomeView"). Company, Branch, Profile, KYC, Settings and Notifications never match.
  static const List<String> _lockedWords = [
    'product', 'offer', 'contract', 'deal', 'consignment', 'challan', 'rfq', 'requirement', 'interest',
    'bid', 'driver', 'vehicle', 'categor', 'brand', 'master', 'analytic', 'logistic', 'media', 'shipment',
    'transport', 'order', 'negotiation', 'tag', 'quotation', 'salesman', 'stock', '/admin/',
  ];

  static const List<String> _openWords = [
    'dashboard', 'company', 'branch', 'kyc', 'profile', 'setting', 'notification', 'support', 'about',
    'document', 'download', 'login', 'register', 'password', 'otp', 'splash', 'onboarding', 'legal',
    'policy', 'terms', 'privacy', 'choose-panel', 'main-nav', 'home',
  ];

  static bool screenLocked(String? routeName) {
    if (!active || routeName == null) return false;
    final name = routeName.toLowerCase();
    // Always open (the role dashboards, company, branch, KYC ... even when the name has "transport" etc.).
    if (_openWords.any(name.contains)) return false;
    return _lockedWords.any(name.contains);
  }

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

/// Closes a business screen opened while KYC is pending (a dashboard KPI card, a quick button, a
/// notification ...) and explains why: one guard for every way into those screens.
class KycRouteGuard extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is! PageRoute || !KycLock.screenLocked(route.settings.name)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = route.navigator;
      if (navigator == null || !route.isActive) return;
      navigator.removeRoute(route);
      final context = navigator.context;
      if (context.mounted) KycLock.explain(context);
    });
  }
}
