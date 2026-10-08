import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/admin_challan_model.dart';
import '../service/admin_dc_service.dart';
import 'admin_dc_list_controller.dart';

class AdminDCDetailsController extends GetxController {
  final isLoading = true.obs;
  final isDispatching = false.obs;
  final challanId = 0.obs;

  final challan = Rxn<AdminChallanModel>();
  final rawData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments is int) {
        challanId.value = Get.arguments as int;
      } else if (Get.arguments is AdminChallanModel) {
        challan.value = Get.arguments as AdminChallanModel;
        challanId.value = (Get.arguments as AdminChallanModel).id;
      }
    }

    if (challanId.value > 0) {
      fetchDetails(challanId.value);
    } else {
      isLoading.value = false;
    }
  }

  // ── Fetch Challan Details ────────────────────────────────────────────────
  Future<void> fetchDetails(int id, {bool isRefresh = false}) async {
    try {
      if (!isRefresh && challan.value == null) {
        isLoading.value = true;
      }
      debugPrint("📦 [AdminDCDetailsController] Fetching details for Challan #$id...");

      final data = await AdminDCService.getChallanDetails(id);
      if (data != null) {
        rawData.value = data;
        challan.value = AdminChallanModel.fromJson(data);
        debugPrint("✅ [AdminDCDetailsController] Loaded details for Challan #${challan.value?.displayChallanNo}");
      }
    } catch (e) {
      debugPrint("❌ [AdminDCDetailsController] Error fetching challan details: $e");
      Get.snackbar(
        "Notice",
        "Could not load latest challan details. Pull down to refresh.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Dispatch Shipment Action ─────────────────────────────────────────────
  Future<void> dispatchShipment() async {
    final id = challanId.value;
    if (id <= 0) return;

    try {
      isDispatching.value = true;
      debugPrint("📦 [AdminDCDetailsController] Dispatching shipment for Challan #$id...");

      final result = await AdminDCService.dispatchChallan(id);

      if (result['success'] == true) {
        Get.snackbar(
          "Shipment Dispatched",
          result['message'] ?? "Shipment marked as Dispatched successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          duration: const Duration(seconds: 4),
        );

        // Refresh details to show updated status
        await fetchDetails(id, isRefresh: true);
        _refreshList();
      } else {
        Get.snackbar(
          "Cannot Dispatch",
          result['message'] ?? "Could not dispatch delivery challan.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint("❌ [AdminDCDetailsController] Dispatch Error: $e");
      Get.snackbar(
        "Dispatch Error",
        "An unexpected error occurred: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isDispatching.value = false;
    }
  }

  // ── Manage actions (same rules as the web: only drafts can be edited, cancelled or deleted) ──
  final isWorking = false.obs;

  void _toast(String title, String message, {bool ok = true}) => Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? const Color(0xFF059669) : const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

  String _error(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _refreshList() {
    if (Get.isRegistered<AdminDCListController>()) {
      Get.find<AdminDCListController>().fetchChallans(isRefresh: true);
    }
  }

  /// action: deliver | cancel (dispatch keeps using [dispatchShipment]).
  Future<void> runAction(String action) async {
    final id = challanId.value;
    if (id <= 0) return;
    try {
      isWorking.value = true;
      final result = await AdminDCService.challanAction(id, action);
      _toast('Done', (result['message'] ?? 'Delivery challan updated.').toString());
      await fetchDetails(id, isRefresh: true);
      _refreshList();
    } catch (e) {
      _toast('Could not update challan', _error(e), ok: false);
    } finally {
      isWorking.value = false;
    }
  }

  Future<bool> saveEdit(Map<String, dynamic> body) async {
    final id = challanId.value;
    try {
      isWorking.value = true;
      final result = await AdminDCService.updateChallan(id, body);
      _toast('Challan updated', (result['message'] ?? 'Delivery challan updated successfully.').toString());
      await fetchDetails(id, isRefresh: true);
      _refreshList();
      return true;
    } catch (e) {
      _toast('Could not update challan', _error(e), ok: false);
      return false;
    } finally {
      isWorking.value = false;
    }
  }

  Future<void> deleteChallan() async {
    final id = challanId.value;
    try {
      isWorking.value = true;
      final result = await AdminDCService.deleteChallan(id);
      _refreshList();
      Get.back(result: true);
      _toast('Challan deleted', (result['message'] ?? 'Delivery challan deleted.').toString());
    } catch (e) {
      _toast('Could not delete challan', _error(e), ok: false);
    } finally {
      isWorking.value = false;
    }
  }
}
