import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modules/seller/notifications/model/notification_model.dart';
import '../modules/products/view/product_detail.dart';
import '../modules/buyer/offers/view/buyer_offers_view.dart';
import '../modules/buyer/branch/view/buyer_branch_view.dart';
import '../modules/buyer/delivery_challan/view/buyer_delivery_challan_view.dart';
import '../modules/seller/products/view/seller_product_view.dart';
import '../modules/seller/products/view/seller_offer_interests_view.dart';
import '../modules/seller/branches/view/seller_branches_view.dart';
import '../modules/seller/challans/view/seller_delivery_challan_view.dart';
import '../modules/seller/notifications/view/seller_notification_view.dart';
import '../modules/contracts/view/contract_view.dart';
import '../modules/contracts/view/contract_details_view.dart';
import '../modules/seller/contracts/view/seller_contract_detail_view.dart';
import '../modules/seller/contracts/view/seller_contracts_view.dart';
import '../services/product_services.dart';
import '../utils/app_preferences.dart';
import 'notification_services.dart';
import 'package:daalsetu/utils/global_error_handler.dart';
import '../modules/buyer/branch/controller/buyer_branch_controller.dart';
import '../modules/seller/branches/controller/seller_branch_controller.dart';
import '../modules/branches/controller/branch_controller.dart';

class RealtimeNotificationService extends GetxService {
  static RealtimeNotificationService get to => Get.find<RealtimeNotificationService>();

  Timer? _pollingTimer;
  final Set<int> _knownNotificationIds = {};
  final Set<int> _dismissedNotificationIds = {};
  bool _isFirstCheck = true;
  bool _storageLoaded = false;
  int _pollingGeneration = 0;
  String? _storageUserId;

  final RxInt unreadCount = 0.obs;
  final RxList<AppNotificationModel> latestNotifications = <AppNotificationModel>[].obs;
  final RxBool isPolling = false.obs;

  /// Currently visible notification banner at the top of the screen
  final Rx<AppNotificationModel?> activeBannerNotification = Rx<AppNotificationModel?>(null);
  final List<AppNotificationModel> _bannerQueue = [];

  static const String _seenIdsPrefKey = "seen_realtime_notification_ids";
  static const String _dismissedIdsPrefKey =
      "dismissed_realtime_notification_ids";

  @override
  void onInit() {
    super.onInit();
    _initService();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  Future<void> _initService() async {
    // Signed out (login screen): nothing to poll; login starts polling.
    final token = await AppPreferences.getAccessToken();
    if (token == null || token.isEmpty) return;
    await _loadSeenIdsFromStorage();
    startPolling();
  }

  /// Start polling every 5 seconds for responsive real-time notifications
  void startPolling() {
    stopPolling();
    isPolling.value = true;
    _checkNotifications(); // Immediate initial check
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Screen off: Android blocks background network, so skip instead of failing.
      if (AppForeground.isActive) {
        _checkNotifications();
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollingGeneration++;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    isPolling.value = false;
  }

  /// Manual refresh
  Future<void> refreshNow() async {
    await _checkNotifications();
  }

  /// Reset state on logout
  void clearOnLogout() {
    stopPolling();
    activeBannerNotification.value = null;
    _bannerQueue.clear();
    _knownNotificationIds.clear();
    _dismissedNotificationIds.clear();
    _isFirstCheck = true;
    _storageLoaded = false;
    _storageUserId = null;
    unreadCount.value = 0;
    latestNotifications.clear();
  }

  /// Load persisted seen notification IDs from SharedPreferences
  Future<void> _loadSeenIdsFromStorage() async {
    try {
      final userId = await AppPreferences.getUserId();
      if (userId == null || userId.isEmpty) {
        _storageLoaded = true;
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('${_seenIdsPrefKey}_$userId') ?? [];
      final dismissed =
          prefs.getStringList('${_dismissedIdsPrefKey}_$userId') ?? [];
      _knownNotificationIds.clear();
      _dismissedNotificationIds.clear();
      _knownNotificationIds.addAll(list.map((e) => int.tryParse(e)).whereType<int>());
      _dismissedNotificationIds.addAll(
        dismissed.map((e) => int.tryParse(e)).whereType<int>(),
      );
      _storageUserId = userId;
      _storageLoaded = true;
    } catch (_) {
      _storageLoaded = true;
    }
  }

  /// Save known notification IDs to SharedPreferences
  Future<void> _saveSeenIdsToStorage() async {
    try {
      final userId = _storageUserId ?? await AppPreferences.getUserId();
      if (userId == null || userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final idsToSave = _knownNotificationIds.toList();
      if (idsToSave.length > 250) {
        idsToSave.removeRange(0, idsToSave.length - 250);
      }
      await prefs.setStringList(
        '${_seenIdsPrefKey}_$userId',
        idsToSave.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  Future<void> _saveDismissedIdsToStorage() async {
    try {
      final userId = _storageUserId ?? await AppPreferences.getUserId();
      if (userId == null || userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final idsToSave = _dismissedNotificationIds.toList();
      if (idsToSave.length > 250) {
        idsToSave.removeRange(0, idsToSave.length - 250);
      }
      await prefs.setStringList(
        '${_dismissedIdsPrefKey}_$userId',
        idsToSave.map((e) => e.toString()).toList(),
      );
    } catch (_) {}
  }

  bool _isCurrentPoll(int generation, int sessionVersion) =>
      isPolling.value &&
      generation == _pollingGeneration &&
      sessionVersion == AppPreferences.sessionVersion;

  /// Check notifications from API
  Future<void> _checkNotifications() async {
    try {
      if (!isPolling.value) return;
      final generation = _pollingGeneration;
      final sessionVersion = AppPreferences.sessionVersion;
      final token = await AppPreferences.getAccessToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final userId = await AppPreferences.getUserId();
      if (!_isCurrentPoll(generation, sessionVersion)) return;
      if (_storageUserId != userId) {
        _storageLoaded = false;
        _isFirstCheck = true;
      }

      // Ensure storage was loaded before checking
      if (!_storageLoaded) {
        await _loadSeenIdsFromStorage();
      }
      if (!_isCurrentPoll(generation, sessionVersion)) return;

      // 1. Fetch latest notifications
      final res = await NotificationServices.getNotifications(page: 1, pageSize: 10, silent: true);
      if (!_isCurrentPoll(generation, sessionVersion)) return;
      final rawList = (res['results'] is List)
          ? res['results'] as List
          : ((res['data'] is List)
              ? res['data'] as List
              : (res is List ? res as List : []));
      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => AppNotificationModel.fromJson(e))
          .toList();

      latestNotifications.assignAll(items);

      // 2. Fetch unread count from API and cross-check
      try {
        final count = await NotificationServices.getUnreadCount(silent: true);
        if (!_isCurrentPoll(generation, sessionVersion)) return;
        unreadCount.value = count;
      } catch (_) {
        unreadCount.value = items.where((n) => n.isRead == false).length;
      }

      // If all latest notifications are read, force count to 0 if API is out of sync
      if (items.isNotEmpty && items.every((n) => n.isRead == true)) {
        unreadCount.value = 0;
      }

      // First run handling:
      if (_isFirstCheck) {
        _isFirstCheck = false;
        final prefs = await SharedPreferences.getInstance();
        final hadPriorHistory = userId != null &&
            prefs.containsKey('${_seenIdsPrefKey}_$userId');

        if (!hadPriorHistory) {
          // Cold fresh install: Seed all existing items so user isn't flooded with old history
          for (var n in items) {
            if (n.id != null) {
              _knownNotificationIds.add(n.id!);
            }
          }
          await _saveSeenIdsToStorage();
          return;
        }
      }

      // Identify newly arrived notifications that haven't been shown yet
      final List<AppNotificationModel> newNotifications = [];
      for (var n in items) {
        if (n.id != null && !_knownNotificationIds.contains(n.id!)) {
          _knownNotificationIds.add(n.id!);
          // Only show banner for unread notifications
          if (n.isRead != true) {
            newNotifications.add(n);
          }
        }
      }

      if (newNotifications.isNotEmpty) {
        await _saveSeenIdsToStorage();
        // Check if any new notification is branch-related and notify branch controllers immediately
        for (var newNotif in newNotifications) {
          if (isBranchNotification(newNotif)) {
            notifyBranchControllers(newNotif);
          }
        }
        // Enqueue pop-up banner for each new notification (oldest first so order is preserved)
        for (var newNotif in newNotifications.reversed) {
          enqueueBanner(newNotif);
        }
      }
    } catch (_) {
      // Keep silent for background polling
    }
  }

  /// Check whether a notification is related to branch network
  static bool isBranchNotification(AppNotificationModel notification) {
    final title = (notification.title ?? "").toLowerCase();
    final message = (notification.message ?? "").toLowerCase();
    final type = (notification.type ?? "").toLowerCase();
    final url = (notification.redirectUrl ?? "").toLowerCase();

    return type.contains('branch') ||
        title.contains('branch') ||
        message.contains('branch') ||
        url.contains('branch');
  }

  /// Triggers immediate refresh on all active branch controllers
  static void notifyBranchControllers(AppNotificationModel notification) {
    try {
      if (Get.isRegistered<BuyerBranchController>()) {
        Get.find<BuyerBranchController>().handleBranchNotification(notification);
      }
      if (Get.isRegistered<SellerBranchController>()) {
        Get.find<SellerBranchController>().fetchBranches();
      }
      if (Get.isRegistered<BranchController>()) {
        Get.find<BranchController>().fetchBranches();
      }
    } catch (_) {}
  }

  /// Show floating real-time banner on top of the screen (Instance or Static)
  static void showNotificationPopup(AppNotificationModel notification) {
    if (Get.isRegistered<RealtimeNotificationService>()) {
      RealtimeNotificationService.to.enqueueBanner(notification);
    }
  }

  /// Enqueue notification banner for display
  void enqueueBanner(AppNotificationModel notification) {
    // Ignore late API/controller events after logout stopped polling.
    if (!isPolling.value) return;
    if (notification.id != null &&
        _dismissedNotificationIds.contains(notification.id)) {
      return;
    }
    if (isBranchNotification(notification)) {
      notifyBranchControllers(notification);
    }

    if (activeBannerNotification.value == null) {
      activeBannerNotification.value = notification;
    } else {
      // Avoid duplicate banner in queue
      final isAlreadyQueued = _bannerQueue.any((n) => n.id == notification.id && n.id != null);
      if (!isAlreadyQueued && activeBannerNotification.value?.id != notification.id) {
        _bannerQueue.add(notification);
      }
    }
  }

  /// Dismiss current banner and show next in queue if available
  void dismissCurrentBanner() {
    final dismissedId = activeBannerNotification.value?.id;
    if (dismissedId != null) {
      _knownNotificationIds.add(dismissedId);
      _dismissedNotificationIds.add(dismissedId);
      _bannerQueue.removeWhere((item) => item.id == dismissedId);
      unawaited(_saveSeenIdsToStorage());
      unawaited(_saveDismissedIdsToStorage());
    }
    if (_bannerQueue.isNotEmpty) {
      activeBannerNotification.value = _bannerQueue.removeAt(0);
    } else {
      activeBannerNotification.value = null;
    }
  }

  /// User tapped the notification banner card
  Future<void> onBannerTapped(AppNotificationModel notification) async {
    dismissCurrentBanner();

    // Mark as read immediately in background
    if (notification.id != null && notification.isRead != true) {
      NotificationServices.markAsRead(notification.id!);
      if (unreadCount.value > 0) {
        unreadCount.value--;
      }
    }

    await navigateToTarget(notification);
  }

  /// Trigger a pop-up banner directly for a product
  void triggerProductBanner({
    required int productId,
    required String title,
    String? message,
  }) {
    final notif = AppNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: "New Product Added",
      message: message ?? "New product added: $title",
      type: "product",
      relatedProduct: productId,
      timeAgo: "Just now",
      isRead: false,
    );
    enqueueBanner(notif);
  }

  /// Deep link and redirect the user to the relevant screen based on notification content
  static Future<void> navigateToTarget(AppNotificationModel notification) async {
    try {
      final title = (notification.title ?? "").toLowerCase();
      final message = (notification.message ?? "").toLowerCase();
      final type = (notification.type ?? "").toLowerCase();
      final url = notification.redirectUrl ?? "";
      final role = (await AppPreferences.getRole() ?? "").trim().toLowerCase();

      // 1. Try to extract contract ID first if notification relates to contract or deal
      final isContractOrDeal = type.contains('contract') ||
          type.contains('deal') ||
          title.contains('contract') ||
          title.contains('deal') ||
          message.contains('contract') ||
          message.contains('deal');

      int? contractId;
      if (isContractOrDeal) {
        contractId = notification.referenceId;
        // Check url for contract ID (e.g. /contracts/12/ or /api/mobile/contracts/12/)
        if (contractId == null && url.isNotEmpty) {
          final contractMatch = RegExp(r'/(?:contracts|mobile/contracts)/(\d+)').firstMatch(url);
          if (contractMatch != null) {
            contractId = int.tryParse(contractMatch.group(1)!);
          }
        }
        // Check message for contract ID (e.g. Contract #12 or Contract ID: 12)
        if (contractId == null && notification.message != null) {
          final contractMatch = RegExp(r'(?:contract[:\s#]+|deal[:\s#]+)(\d+)', caseSensitive: false).firstMatch(notification.message!);
          if (contractMatch != null) {
            contractId = int.tryParse(contractMatch.group(1)!);
          }
        }
        // Fallback to relatedProduct or generic ID if referenceId wasn't set but type is explicitly contract
        if (contractId == null && (type.contains('contract') || title.contains('contract'))) {
          contractId = notification.relatedProduct;
        }

        // Redirect directly to the Contract Details page
        if (role == 'seller') {
          if (contractId != null && contractId > 0) {
            Get.to(() => SellerContractDetailView(contractId: contractId!));
          } else {
            Get.to(() => const SellerContractsView());
          }
          return;
        } else {
          // Buyer / general user
          if (contractId != null && contractId > 0) {
            Get.to(() => const ContractDetailScreen(), arguments: contractId);
          } else {
            Get.to(() => const ContractsScreen());
          }
          return;
        }
      }

      // 2. Try to extract product/offer ID
      int? productId = notification.relatedProduct ?? notification.referenceId;

      // Check url regex
      if (productId == null && url.isNotEmpty) {
        final match = RegExp(r'/(?:products|offers|buyer-offers|rfqs)/(\d+)').firstMatch(url);
        if (match != null) {
          productId = int.tryParse(match.group(1)!);
        }
      }

      // Check message regex for ID (e.g. ID: 129 or #129)
      if (productId == null && notification.message != null) {
        final match = RegExp(r'(?:id[:\s#]+|#)(\d+)', caseSensitive: false).firstMatch(notification.message!);
        if (match != null) {
          productId = int.tryParse(match.group(1)!);
        }
      }

      // Interest notifications reference the ProductInterest record, while
      // related_product (or manage_product in the URL) identifies the offer.
      final isInterest = type.contains('interest') ||
          title.contains('interest') ||
          message.contains('interest');
      if (isInterest && role == 'seller') {
        int? offerId = notification.relatedProduct;
        if (offerId == null && url.isNotEmpty) {
          final match = RegExp(r'[?&]manage_product=(\d+)').firstMatch(url);
          if (match != null) {
            offerId = int.tryParse(match.group(1)!);
          }
        }

        if (offerId != null && offerId > 0) {
          Get.to(() => const SellerOfferInterestsView(), arguments: offerId);
        } else {
          Get.to(() => const SellerProductView());
        }
        return;
      }

      // Is Product / Offer related?
      final isProductOrOffer = type.contains('product') ||
          type.contains('offer') ||
          title.contains('product') ||
          title.contains('offer') ||
          message.contains('product') ||
          message.contains('offer');

      if (isProductOrOffer) {
        if (productId != null && productId > 0) {
          Get.to(() => ProductDetailScreen(productId: productId!));
          return;
        }

        // If ID not found directly in notification, try searching product by title from message
        // e.g. "New product added: toor dal" -> "toor dal"
        final rawMsg = notification.message ?? "";
        String candidateTitle = "";
        if (rawMsg.contains(":")) {
          candidateTitle = rawMsg.split(":").last.trim().toLowerCase();
        } else if (rawMsg.isNotEmpty) {
          candidateTitle = rawMsg.trim().toLowerCase();
        }

        if (candidateTitle.isNotEmpty) {
          try {
            final products = await ProductService.getProducts();
            final match = products.firstWhereOrNull((p) {
              final pTitle = p.title.toLowerCase().trim();
              return pTitle == candidateTitle ||
                  pTitle.contains(candidateTitle) ||
                  candidateTitle.contains(pTitle);
            });
            if (match != null) {
              Get.to(() => ProductDetailScreen(productId: match.id));
              return;
            }
          } catch (_) {}
        }

        // Role-based Fallback for Products / Offers
        if (role == 'seller') {
          Get.to(() => const SellerProductView());
        } else {
          Get.to(() => const BuyerOffersView());
        }
        return;
      }

      // Branch related
      if (type.contains('branch') || title.contains('branch') || message.contains('branch')) {
        notifyBranchControllers(notification);
        if (role == 'seller') {
          Get.to(() => const SellerBranchesView());
        } else {
          Get.to(() => const BuyerBranchView());
        }
        return;
      }

      // Challan / Transport related
      if (type.contains('challan') ||
          type.contains('transport') ||
          title.contains('challan') ||
          title.contains('dispatch') ||
          message.contains('challan') ||
          message.contains('dispatch')) {
        if (role == 'seller') {
          Get.to(() => const SellerDeliveryChallanView());
        } else {
          Get.to(() => const BuyerDeliveryChallanView());
        }
        return;
      }

      // Default Fallback: Open Notifications View
      Get.to(() => const SellerNotificationView());
    } catch (_) {
      // In case of any navigation error, fall back safely to notification view
      try {
        Get.to(() => const SellerNotificationView());
      } catch (_) {}
    }
  }
}
