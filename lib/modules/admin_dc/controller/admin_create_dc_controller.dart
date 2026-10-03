import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../contracts/model/contract_model.dart';
import '../service/admin_dc_service.dart';

class AdminCreateDCController extends GetxController {
  final isLoadingContracts = false.obs;
  final isSubmitting = false.obs;

  final contracts = <ContractModel>[].obs;
  final filteredContracts = <ContractModel>[].obs;
  final selectedContract = Rxn<ContractModel>();
  final contractSearchQuery = ''.obs;

  // Text Controllers
  final truckNumberController = TextEditingController();
  final driverNameController = TextEditingController();
  final driverPhoneController = TextEditingController();
  final quantityController = TextEditingController();
  final bagCountController = TextEditingController();
  final dispatchDateController = TextEditingController();
  final remarksController = TextEditingController();
  final loadingFromController = TextEditingController();
  final loadingToController = TextEditingController();

  DateTime selectedDispatchDate = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    // Default dispatch date is today
    dispatchDateController.text = DateFormat('yyyy-MM-dd').format(selectedDispatchDate);
    fetchContracts();

    // If a contract ID was passed as argument (e.g. from ContractDetailScreen)
    if (Get.arguments != null && Get.arguments is int) {
      final preselectedId = Get.arguments as int;
      _selectContractById(preselectedId);
    }
  }

  @override
  void onClose() {
    truckNumberController.dispose();
    driverNameController.dispose();
    driverPhoneController.dispose();
    quantityController.dispose();
    bagCountController.dispose();
    dispatchDateController.dispose();
    remarksController.dispose();
    loadingFromController.dispose();
    loadingToController.dispose();
    super.onClose();
  }

  // ── Fetch Active Contracts ───────────────────────────────────────────────
  Future<void> fetchContracts({bool isRefresh = false}) async {
    try {
      isLoadingContracts.value = true;
      debugPrint("📦 [AdminCreateDCController] Loading active contracts...");
      final list = await AdminDCService.getActiveContracts();
      contracts.assignAll(list);
      filteredContracts.assignAll(list);
      debugPrint("✅ [AdminCreateDCController] Loaded ${contracts.length} contracts.");
    } catch (e) {
      debugPrint("❌ [AdminCreateDCController] Error fetching contracts: $e");
      Get.snackbar(
        "Notice",
        "Could not load contracts. Please pull down to refresh.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E293B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoadingContracts.value = false;
    }
  }

  void filterContracts(String query) {
    contractSearchQuery.value = query.toLowerCase().trim();
    if (contractSearchQuery.value.isEmpty) {
      filteredContracts.assignAll(contracts);
    } else {
      filteredContracts.assignAll(
        contracts.where((c) {
          final idMatch = c.contractId.toLowerCase().contains(contractSearchQuery.value);
          final productMatch = c.productTitle.toLowerCase().contains(contractSearchQuery.value);
          final buyerMatch = c.buyerName.toLowerCase().contains(contractSearchQuery.value) ||
              c.displayBuyerId.toLowerCase().contains(contractSearchQuery.value);
          final sellerMatch = c.sellerName.toLowerCase().contains(contractSearchQuery.value) ||
              c.displaySellerId.toLowerCase().contains(contractSearchQuery.value);
          return idMatch || productMatch || buyerMatch || sellerMatch;
        }).toList(),
      );
    }
  }

  void _selectContractById(int contractId) async {
    if (contracts.isEmpty) {
      await fetchContracts();
    }
    final match = contracts.firstWhereOrNull((c) => c.id == contractId);
    if (match != null) {
      selectContract(match);
    }
  }

  // ── Select Contract & Auto-fill Fields ────────────────────────────────────
  void selectContract(ContractModel contract) {
    selectedContract.value = contract;

    // Auto-fill contract data
    quantityController.text = contract.dealQuantity;
    loadingFromController.text = contract.loadingFrom;
    loadingToController.text = contract.loadingTo;

    debugPrint("📦 [AdminCreateDCController] Selected Contract: ${contract.contractId}");
    debugPrint("   Seller: ${contract.displaySellerId}");
    debugPrint("   Buyer: ${contract.displayBuyerId}");
    debugPrint("   Commodity: ${contract.productTitle}");
    debugPrint("   Quantity: ${contract.dealQuantity} ${contract.quantityUnit}");
  }

  void clearSelectedContract() {
    selectedContract.value = null;
    quantityController.clear();
    loadingFromController.clear();
    loadingToController.clear();
  }

  // ── Date Picker ──────────────────────────────────────────────────────────
  Future<void> pickDispatchDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDispatchDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF5B400),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDispatchDate = picked;
      dispatchDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ── Submit Create DC ─────────────────────────────────────────────────────
  Future<void> submitDeliveryChallan() async {
    // 1. Validation
    if (selectedContract.value == null) {
      Get.snackbar(
        "Validation Error",
        "Please select a Confirmed Contract first.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    final truckNo = truckNumberController.text.trim();
    if (truckNo.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please enter the Truck / Vehicle Number.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    final driverName = driverNameController.text.trim();
    if (driverName.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please enter the Driver's Name.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    final contract = selectedContract.value!;

    // 2. Build Payload
    final payload = {
      "contract_id": contract.id,
      "order": contract.id,
      "seller_name": contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contract.sellerName,
      "buyer_name": contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contract.buyerName,
      "product_title": contract.productTitle,
      "truck_number": truckNo,
      "vehicle_number": truckNo,
      "driver_name": driverName,
      "driver_mobile": driverPhoneController.text.trim(),
      "driver_phone": driverPhoneController.text.trim(),
      "dispatch_date": dispatchDateController.text.trim(),
      "quantity": double.tryParse(quantityController.text.trim()) ?? 0.0,
      "quantity_unit": contract.quantityUnit.isNotEmpty ? contract.quantityUnit.toLowerCase() : "qtl",
      "bag_count": int.tryParse(bagCountController.text.trim()) ?? 0,
      "loading_from": loadingFromController.text.trim(),
      "loading_to": loadingToController.text.trim(),
      "narration": remarksController.text.trim(),
      "remarks": remarksController.text.trim(),
    };

    debugPrint("📦 [AdminCreateDCController] Submitting DC payload: $payload");

    try {
      isSubmitting.value = true;
      final result = await AdminDCService.createDeliveryChallan(payload);
      debugPrint("📦 [AdminCreateDCController] API Response: $result");

      if (result['success'] == true) {
        Get.snackbar(
          "Success",
          result['message'] ?? "Delivery Challan generated successfully!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          duration: const Duration(seconds: 3),
        );

        // Return true to refresh list
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back(result: true);
      } else {
        final errorMsg = result['message'] ?? "Failed to create Delivery Challan.";
        Get.snackbar(
          "Cannot Create Challan",
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint("❌ [AdminCreateDCController] Submit Error: $e");
      Get.snackbar(
        "Submission Error",
        "An unexpected error occurred: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error_outline, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
