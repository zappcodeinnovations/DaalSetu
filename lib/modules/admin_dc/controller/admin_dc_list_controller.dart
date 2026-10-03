import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/admin_challan_model.dart';
import '../service/admin_dc_service.dart';

class AdminDCListController extends GetxController {
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  final challans = <AdminChallanModel>[].obs;
  final filteredChallans = <AdminChallanModel>[].obs;

  // Filter & Search states
  final selectedStatus = 'all'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchChallans();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ── Reactive KPI Counts ──────────────────────────────────────────────────
  int get totalCount => challans.length;

  int get pendingCount => challans.where((c) {
        final s = (c.status ?? '').toLowerCase();
        return s == 'pending' || s.isEmpty;
      }).length;

  int get dispatchedCount => challans.where((c) {
        final s = (c.status ?? '').toLowerCase();
        return s == 'dispatched' || s == 'in_transit';
      }).length;

  int get deliveredCount => challans.where((c) {
        final s = (c.status ?? '').toLowerCase();
        return s == 'delivered' || s == 'received';
      }).length;

  // ── Fetch Challans from Service ──────────────────────────────────────────
  Future<void> fetchChallans({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
      errorMessage.value = '';

      debugPrint("📦 [AdminDCListController] Fetching challans... (isRefresh: $isRefresh)");
      final list = await AdminDCService.getDeliveryChallans();

      challans.assignAll(list);
      applyFilter();

      debugPrint("✅ [AdminDCListController] Loaded ${challans.length} challans.");
    } catch (e) {
      debugPrint("❌ [AdminDCListController] Error loading challans: $e");
      errorMessage.value = "Failed to load Delivery Challans: $e";
      Get.snackbar(
        "Notice",
        "Could not load Delivery Challans. Please pull down to refresh.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.info_outline, color: Color(0xFFF5B400)),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Status Filter Selection ──────────────────────────────────────────────
  void setStatus(String status) {
    selectedStatus.value = status;
    applyFilter();
  }

  // ── Search Query Changed ─────────────────────────────────────────────────
  void onSearchChanged(String query) {
    searchQuery.value = query.trim().toLowerCase();
    applyFilter();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilter();
  }

  // ── Apply Combined Status & Search Filters ───────────────────────────────
  void applyFilter() {
    final status = selectedStatus.value.toLowerCase();
    final query = searchQuery.value;

    filteredChallans.assignAll(
      challans.where((item) {
        // Status Match
        bool matchesStatus = true;
        final itemStatus = (item.status ?? 'pending').toLowerCase();
        if (status != 'all') {
          if (status == 'pending') {
            matchesStatus = itemStatus == 'pending' || itemStatus.isEmpty;
          } else if (status == 'dispatched') {
            matchesStatus = itemStatus == 'dispatched' || itemStatus == 'in_transit';
          } else if (status == 'delivered') {
            matchesStatus = itemStatus == 'delivered' || itemStatus == 'received';
          } else {
            matchesStatus = itemStatus == status;
          }
        }

        // Search Match
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final challanNo = item.displayChallanNo.toLowerCase();
          final truck = (item.truckNumber ?? '').toLowerCase();
          final driver = (item.driverName ?? '').toLowerCase();
          final seller = item.displaySeller.toLowerCase();
          final buyer = item.displayBuyer.toLowerCase();
          final commodity = item.displayCommodity.toLowerCase();

          matchesQuery = challanNo.contains(query) ||
              truck.contains(query) ||
              driver.contains(query) ||
              seller.contains(query) ||
              buyer.contains(query) ||
              commodity.contains(query);
        }

        return matchesStatus && matchesQuery;
      }).toList(),
    );
  }
}
