import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/seller_services.dart';
import '../../../../services/realtime_notification_service.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../nav_bar/controller/nav_controller.dart';
import '../../../seller/branches/model/seller_branch_model.dart';
import '../../../seller/notifications/model/notification_model.dart';

class BuyerBranchController extends GetxController with WidgetsBindingObserver {
  var isLoading = false.obs;
  var primaryBranch = Rxn<SellerBranchModel>();
  var myBranches = <SellerBranchModel>[].obs;
  var pendingRequests = <SellerBranchModel>[].obs;

  final Set<int> _leftBranchIds = {};
  final Set<String> _leftBranchCodes = {};

  Worker? _navWorker;
  Worker? _notifBannerWorker;
  Worker? _notifListWorker;

  // Search & Filter state
  final searchQuery = ''.obs;
  final selectedTypeFilter = 'all'.obs; // 'all', 'primary', 'additional', 'pending'
  final TextEditingController searchTextController = TextEditingController();

  void setSearchQuery(String query) {
    searchQuery.value = query.trim();
  }

  void setTypeFilter(String type) {
    selectedTypeFilter.value = type;
  }

  void applyFilter() {
    searchQuery.value = searchTextController.text.trim();
  }

  void resetFilter() {
    searchTextController.clear();
    searchQuery.value = '';
    selectedTypeFilter.value = 'all';
  }

  bool get isFilterActive =>
      searchQuery.value.isNotEmpty || selectedTypeFilter.value != 'all';

  bool _matchesQuery(SellerBranchModel branch, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final code = (branch.branchCode ?? '').toLowerCase();
    final loc = (branch.locationName ?? '').toLowerCase();
    final city = (branch.city ?? '').toLowerCase();
    final state = (branch.state ?? '').toLowerCase();
    final area = (branch.area ?? '').toLowerCase();
    final admin = (branch.adminName ?? '').toLowerCase();
    final user = (branch.userName ?? '').toLowerCase();

    return code.contains(q) ||
        loc.contains(q) ||
        city.contains(q) ||
        state.contains(q) ||
        area.contains(q) ||
        admin.contains(q) ||
        user.contains(q);
  }

  /// Filtered Primary Branch (null if excluded by type or search)
  SellerBranchModel? get filteredPrimaryBranch {
    final pb = primaryBranch.value;
    if (pb == null) return null;
    if (selectedTypeFilter.value == 'additional' ||
        selectedTypeFilter.value == 'pending') {
      return null;
    }
    return _matchesQuery(pb, searchQuery.value) ? pb : null;
  }

  /// Filtered My Branches (Additional connected branches)
  List<SellerBranchModel> get filteredMyBranches {
    if (selectedTypeFilter.value == 'primary' ||
        selectedTypeFilter.value == 'pending') {
      return [];
    }
    return myBranches
        .where((b) => _matchesQuery(b, searchQuery.value))
        .toList();
  }

  /// Filtered Pending Requests
  List<SellerBranchModel> get filteredPendingRequests {
    if (selectedTypeFilter.value == 'primary' ||
        selectedTypeFilter.value == 'additional') {
      return [];
    }
    return pendingRequests
        .where((b) => _matchesQuery(b, searchQuery.value))
        .toList();
  }

  /// True if any branches match current filters
  bool get hasFilteredResults =>
      filteredPrimaryBranch != null ||
      filteredMyBranches.isNotEmpty ||
      filteredPendingRequests.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _clearLegacyDiskCache();
    fetchBranches();
    _setupListeners();
  }

  @override
  void onReady() {
    super.onReady();
    _setupListeners();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _navWorker?.dispose();
    _notifBannerWorker?.dispose();
    _notifListWorker?.dispose();
    searchTextController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchBranches(silent: true);
    }
  }

  void _setupListeners() {
    // 1. Listen for BottomNavController tab focus (index 4 is Buyer Branch tab)
    if (_navWorker == null && Get.isRegistered<BottomNavController>()) {
      final nav = Get.find<BottomNavController>();
      _navWorker = ever(nav.selectedIndex, (int index) {
        if (index == 4) {
          fetchBranches(silent: true);
        }
      });
    }

    // 2. Listen for RealtimeNotificationService notifications
    if (Get.isRegistered<RealtimeNotificationService>()) {
      final rns = RealtimeNotificationService.to;
      _notifBannerWorker ??= ever(rns.activeBannerNotification, (AppNotificationModel? notif) {
        if (notif != null && _isBranchNotification(notif)) {
          handleBranchNotification(notif);
        }
      });

      _notifListWorker ??= ever(rns.latestNotifications, (List<AppNotificationModel> list) {
        for (final notif in list) {
          if (_isBranchNotification(notif) && notif.isRead != true) {
            handleBranchNotification(notif);
            break;
          }
        }
      });
    }
  }

  bool _isBranchNotification(AppNotificationModel notif) {
    final title = (notif.title ?? '').toLowerCase();
    final msg = (notif.message ?? '').toLowerCase();
    final type = (notif.type ?? '').toLowerCase();
    final url = (notif.redirectUrl ?? '').toLowerCase();
    return title.contains('branch') ||
        msg.contains('branch') ||
        type.contains('branch') ||
        url.contains('branch');
  }

  /// Handles branch approval/rejection notification immediately
  void handleBranchNotification(AppNotificationModel notif) {
    final title = (notif.title ?? '').toLowerCase();
    final msg = (notif.message ?? '').trim();
    final lowerMsg = msg.toLowerCase();

    final isApproval = title.contains('approv') ||
        lowerMsg.contains('approv') ||
        title.contains('accept') ||
        lowerMsg.contains('accept') ||
        title.contains('joined') ||
        lowerMsg.contains('joined');

    final isRejection = title.contains('reject') ||
        lowerMsg.contains('reject') ||
        title.contains('declin') ||
        lowerMsg.contains('declin') ||
        title.contains('cancel') ||
        lowerMsg.contains('cancel');

    if (isApproval) {
      String? matchedCode;
      SellerBranchModel? pendingItem;

      for (final req in pendingRequests) {
        final code = req.branchCode?.trim().toUpperCase();
        if (code != null && code.isNotEmpty && msg.toUpperCase().contains(code)) {
          matchedCode = code;
          pendingItem = req;
          break;
        }
      }

      if (matchedCode == null) {
        final match = RegExp(r'(?:for|branch|code)\s+([A-Z0-9]{4,12})', caseSensitive: false).firstMatch(msg);
        if (match != null) {
          matchedCode = match.group(1)?.toUpperCase();
          pendingItem = pendingRequests.firstWhereOrNull((r) =>
              r.branchCode?.trim().toUpperCase() == matchedCode);
        }
      }

      if (matchedCode != null && matchedCode.isNotEmpty) {
        _leftBranchCodes.remove(matchedCode);
        if (pendingItem?.id != null) _leftBranchIds.remove(pendingItem!.id);
        if (pendingItem?.branchId != null) _leftBranchIds.remove(pendingItem!.branchId);

        // Optimistically remove from pending requests immediately
        pendingRequests.removeWhere((r) =>
            r.branchCode?.trim().toUpperCase() == matchedCode ||
            (pendingItem != null && (r.id == pendingItem.id || r.id == pendingItem.branchId)));

        // Optimistically add to myBranches if not present
        final alreadyInMyBranches = myBranches.any((b) =>
            b.branchCode?.trim().toUpperCase() == matchedCode);
        final alreadyInPrimary = primaryBranch.value?.branchCode?.trim().toUpperCase() == matchedCode;

        if (!alreadyInMyBranches && !alreadyInPrimary && pendingItem != null) {
          myBranches.add(SellerBranchModel(
            id: pendingItem.branchId ?? pendingItem.id,
            branchId: pendingItem.branchId ?? pendingItem.id,
            branchCode: matchedCode,
            locationName: pendingItem.locationName ?? "Branch $matchedCode",
            city: pendingItem.city,
            state: pendingItem.state,
            area: pendingItem.area,
            isPrimary: false,
            status: 'active',
          ));
        }
      }
    } else if (isRejection) {
      for (final req in pendingRequests) {
        final code = req.branchCode?.trim().toUpperCase();
        if (code != null && code.isNotEmpty && msg.toUpperCase().contains(code)) {
          pendingRequests.removeWhere((r) => r.branchCode?.trim().toUpperCase() == code);
          break;
        }
      }
    }

    // Always fetch latest authoritative data from backend
    fetchBranches(silent: true);
  }

  /// Wipes legacy disk cache from previous iterations so nothing is falsely blocked
  Future<void> _clearLegacyDiskCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("buyer_left_branch_ids");
      await prefs.remove("buyer_left_branch_codes");
    } catch (_) {}
  }

  Future<void> fetchBranches({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      final res = await SellerServices.getSellerBranches(silent: silent);
      if (res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;

        // 1. Parse Pending Requests first
        final rawPending = data['pending_requests'] is List ? (data['pending_requests'] as List) : [];
        final parsedPending = rawPending
            .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
            .toList();
        pendingRequests.value = parsedPending;

        final pendingBranchIds = <int>{};
        final pendingCodes = <String>{};

        for (final p in rawPending) {
          if (p is Map<String, dynamic>) {
            final bId = p['branch_id'] ?? p['id'];
            if (bId is int) {
              pendingBranchIds.add(bId);
              _leftBranchIds.remove(bId);
            }
            final code = (p['branch_code'] ?? p['code'])?.toString().trim().toUpperCase();
            if (code != null && code.isNotEmpty) {
              pendingCodes.add(code);
              _leftBranchCodes.remove(code);
            }
          }
        }

        // 2. Parse Primary Branch
        if (data['primary_branch'] is Map<String, dynamic>) {
          final pb = SellerBranchModel.fromJson(data['primary_branch']);
          final code = pb.branchCode?.trim().toUpperCase();
          final isLeft = (pb.id != null && _leftBranchIds.contains(pb.id)) ||
              (code != null && _leftBranchCodes.contains(code));
          final isPending = (pb.id != null && pendingBranchIds.contains(pb.id)) ||
              (code != null && pendingCodes.contains(code));
          if (!isLeft && !isPending) {
            primaryBranch.value = pb;
          } else {
            primaryBranch.value = null;
          }
        } else {
          primaryBranch.value = null;
        }

        // 3. Parse My Branches (exclude pending requests or branches explicitly left in this session)
        if (data['my_branches'] is List) {
          myBranches.value = (data['my_branches'] as List)
              .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
              .where((b) {
                if (b.id == null) return false;
                final code = b.branchCode?.trim().toUpperCase();
                // If it is in pending requests, it is awaiting approval, NOT in My Branches
                if (pendingBranchIds.contains(b.id)) return false;
                if (code != null && pendingCodes.contains(code)) return false;
                // If explicitly left in this session, keep it hidden
                if (_leftBranchIds.contains(b.id)) return false;
                if (code != null && _leftBranchCodes.contains(code)) return false;
                return true;
              })
              .toList();
        } else {
          myBranches.clear();
        }
      }
    } catch (e) {
      if (!silent) {
        AppSnackbar.showError(title: "Error", message: e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> joinBranchByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;
    try {
      // User is actively requesting to join, unblock any left-branch filters
      _leftBranchIds.clear();
      _leftBranchCodes.clear();

      final res = await SellerServices.requestBranchByCode(cleanCode);
      await fetchBranches();

      final msg = res['message']?.toString() ?? "Branch request submitted successfully";
      if (msg.toLowerCase().contains("already")) {
        AppSnackbar.showInfo(
          title: "Branch Notice",
          message: msg,
          duration: const Duration(seconds: 4),
        );
      } else {
        AppSnackbar.showSuccess(
          title: "Success",
          message: msg,
          duration: const Duration(seconds: 4),
        );
      }
      return true;
    } catch (e) {
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  Future<void> cancelRequest(int branchOrReqId, {int? branchId, String? branchCode}) async {
    try {
      final targetId = branchId ?? branchOrReqId;
      final res = await SellerServices.cancelBranchRequest(targetId);
      _leftBranchIds.add(targetId);
      if (branchId != null) _leftBranchIds.add(branchOrReqId);
      if (branchCode != null && branchCode.isNotEmpty) {
        _leftBranchCodes.add(branchCode.trim().toUpperCase());
      }

      pendingRequests.removeWhere((r) =>
          r.id == branchOrReqId ||
          r.id == targetId ||
          (r.branchId != null && r.branchId == targetId));
      await fetchBranches();
      pendingRequests.removeWhere((r) =>
          r.id == branchOrReqId ||
          r.id == targetId ||
          (r.branchId != null && r.branchId == targetId));
      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Request cancelled successfully",
      );
    } catch (e) {
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
      );
    }
  }

  Future<void> makePrimaryBranch(int branchId) async {
    try {
      final res = await SellerServices.makePrimaryBranch(branchId);
      await fetchBranches();
      if (res['success'] == false) {
        AppSnackbar.showError(
          title: "Error",
          message: res['message']?.toString() ?? "Could not change primary branch",
        );
        return;
      }
      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message']?.toString() ?? "Primary branch updated",
      );
    } catch (e) {
      await fetchBranches();
      AppSnackbar.showError(title: "Error", message: e.toString());
    }
  }

  Future<void> leaveBranch(int branchId, {String? branchCode}) async {
    try {
      _leftBranchIds.add(branchId);
      if (branchCode != null && branchCode.isNotEmpty) {
        _leftBranchCodes.add(branchCode.trim().toUpperCase());
      }

      myBranches.removeWhere((b) => b.id == branchId);
      if (primaryBranch.value?.id == branchId) {
        primaryBranch.value = null;
      }
      final res = await SellerServices.leaveBranch(branchId);
      await fetchBranches();
      myBranches.removeWhere((b) => b.id == branchId);
      if (primaryBranch.value?.id == branchId) {
        primaryBranch.value = null;
      }
      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Left branch successfully",
      );
    } catch (e) {
      final err = e.toString();
      if (err.toLowerCase().contains("not added")) {
        _leftBranchIds.add(branchId);
        if (branchCode != null && branchCode.isNotEmpty) {
          _leftBranchCodes.add(branchCode.trim().toUpperCase());
        }
        myBranches.removeWhere((b) => b.id == branchId);
        if (primaryBranch.value?.id == branchId) {
          primaryBranch.value = null;
        }
        AppSnackbar.showInfo(
          title: "Branch Notice",
          message: "You are not added to this branch.",
        );
      } else {
        _leftBranchIds.remove(branchId);
        if (branchCode != null && branchCode.isNotEmpty) {
          _leftBranchCodes.remove(branchCode.trim().toUpperCase());
        }
        await fetchBranches();
        AppSnackbar.showError(
          title: "Error",
          message: err,
        );
      }
    }
  }
}
