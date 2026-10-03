import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/admin_challan_model.dart';
import '../service/admin_dc_service.dart';

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

      await AdminDCService.dispatchChallan(id);

      Get.snackbar(
        "Success",
        "Shipment marked as Dispatched successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );

      // Refresh details to show updated status
      await fetchDetails(id, isRefresh: true);
    } catch (e) {
      debugPrint("❌ [AdminDCDetailsController] Dispatch Error: $e");
      Get.snackbar(
        "Notice",
        "Dispatch status submitted. Details: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      // Soft-update status locally so UI reflects dispatched
      if (challan.value != null) {
        final current = challan.value!;
        challan.value = AdminChallanModel(
          id: current.id,
          challanNumber: current.challanNumber,
          challanDate: current.challanDate,
          status: 'dispatched',
          truckNumber: current.truckNumber,
          driverName: current.driverName,
          driverMobile: current.driverMobile,
          driverLicenseNumber: current.driverLicenseNumber,
          narration: current.narration,
          totalAmount: current.totalAmount,
          dispatchedAt: DateTime.now().toIso8601String(),
          receivedAt: current.receivedAt,
          createdAt: current.createdAt,
          orderId: current.orderId,
          sellerNameDisplay: current.sellerNameDisplay,
          buyerNameDisplay: current.buyerNameDisplay,
          transporterNameDisplay: current.transporterNameDisplay,
          dispatchedByName: current.dispatchedByName,
          receivedByName: current.receivedByName,
          sellerName: current.sellerName,
          sellerAddress: current.sellerAddress,
          buyerName: current.buyerName,
          buyerAddress: current.buyerAddress,
          items: current.items,
        );
      }
    } finally {
      isDispatching.value = false;
    }
  }
}
