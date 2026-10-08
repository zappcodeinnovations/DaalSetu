import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/contract_services.dart';
import '../../contracts/model/contract_details_model.dart';
import '../../contracts/model/contract_model.dart';
import '../../../network/api_client.dart';
import '../service/admin_dc_service.dart';
import 'admin_dc_list_controller.dart';
import '../../../routes/app_routes.dart';

class AdminCreateDCController extends GetxController {
  final isLoadingContracts = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;

  final contracts = <ContractModel>[].obs;
  final filteredContracts = <ContractModel>[].obs;
  final selectedContract = Rxn<ContractModel>();
  final contractSearchQuery = ''.obs;

  /// Contracts with an accepted transport bid (GET /api/transport-bids/?view=accepted), by contract id.
  /// A challan can only be created for these, and they carry the transporter's truck/driver assignment.
  final _acceptedByContract = <int, Map<String, dynamic>>{};

  // Text Controllers - Goods & Items
  final quantityController = TextEditingController();
  final bagCountController = TextEditingController();
  final packingWeightController = TextEditingController();
  final rateController = TextEditingController();
  final amountController = TextEditingController();

  // Text Controllers - Logistics & Transport (matching website)
  final transporterNameController = TextEditingController();
  final truckNumberController = TextEditingController();
  final driverNameController = TextEditingController();
  final driverPhoneController = TextEditingController();
  final driverLicenseController = TextEditingController();

  // Text Controllers - Route, Schedule & Narration
  final dispatchDateController = TextEditingController();
  final loadingFromController = TextEditingController();
  final loadingToController = TextEditingController();
  final remarksController = TextEditingController();

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
    quantityController.dispose();
    bagCountController.dispose();
    packingWeightController.dispose();
    rateController.dispose();
    amountController.dispose();

    transporterNameController.dispose();
    truckNumberController.dispose();
    driverNameController.dispose();
    driverPhoneController.dispose();
    driverLicenseController.dispose();

    dispatchDateController.dispose();
    loadingFromController.dispose();
    loadingToController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  // ── Fetch Active Contracts ───────────────────────────────────────────────
  Future<void> fetchContracts({bool isRefresh = false}) async {
    try {
      isLoadingContracts.value = true;
      debugPrint("📦 [AdminCreateDCController] Loading active contracts from server...");
      var list = await AdminDCService.getActiveContracts();
      try {
        final accepted = await ApiClient.get(endpoint: '/api/transport-bids/?view=accepted', requireAuth: true);
        _acceptedByContract
          ..clear()
          ..addAll({
            for (final item in (accepted is Map && accepted['contracts'] is List ? accepted['contracts'] as List : const []))
              if (item is Map && item['id'] != null) int.parse('${item['id']}'): Map<String, dynamic>.from(item),
          });
        // Same rule as the backend: only contracts whose transport bid was accepted can get a challan.
        list = list.where((c) => _acceptedByContract.containsKey(c.id)).toList();
      } catch (e) {
        debugPrint("⚠️ [AdminCreateDCController] Accepted-bid list unavailable, showing all contracts: $e");
      }
      contracts.assignAll(list);
      filteredContracts.assignAll(list);
      debugPrint("✅ [AdminCreateDCController] Successfully loaded ${contracts.length} contracts.");
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

  // ── Select Contract & Auto-fill All Details (Matching Website 1-to-1) ─────
  Future<void> selectContract(ContractModel contract) async {
    selectedContract.value = contract;
    for (final c in [transporterNameController, truckNumberController, driverNameController, driverPhoneController, driverLicenseController]) {
      c.clear();
    }

    debugPrint("📦 [AdminCreateDCController] ========================================");
    debugPrint("📦 [AdminCreateDCController] Selected Contract: #${contract.contractId} (ID: ${contract.id})");
    debugPrint("   Commodity: ${contract.productTitle}");
    debugPrint("   Seller: ${contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contract.sellerName}");
    debugPrint("   Buyer: ${contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contract.buyerName}");

    // 1. Instant Auto-fill from selected ContractModel
    quantityController.text = contract.dealQuantity;
    loadingFromController.text = contract.loadingFrom;
    loadingToController.text = contract.loadingTo;
    rateController.text = contract.dealAmount;

    // Auto-fill bags count
    if (contract.bagCount != null && contract.bagCount! > 0) {
      bagCountController.text = contract.bagCount.toString();
    } else if (contract.bags != null && contract.bags!.isNotEmpty) {
      final b = double.tryParse(contract.bags!);
      bagCountController.text = b != null ? b.toInt().toString() : contract.bags!;
    }

    if (contract.packingWeightKg != null && contract.packingWeightKg!.isNotEmpty) {
      packingWeightController.text = contract.packingWeightKg!;
    }

    // Auto-fill transport & driver fields if available on contract model
    if (contract.transporterName != null && contract.transporterName!.isNotEmpty) {
      transporterNameController.text = contract.transporterName!;
    }
    if (contract.truckNumber != null && contract.truckNumber!.isNotEmpty) {
      truckNumberController.text = contract.truckNumber!;
    }
    if (contract.driverName != null && contract.driverName!.isNotEmpty) {
      driverNameController.text = contract.driverName!;
    }
    if (contract.driverMobile != null && contract.driverMobile!.isNotEmpty) {
      driverPhoneController.text = contract.driverMobile!;
    }
    if (contract.driverLicenseNumber != null && contract.driverLicenseNumber!.isNotEmpty) {
      driverLicenseController.text = contract.driverLicenseNumber!;
    }

    // Calculate total amount = quantity * rate
    _calculateAmount();

    // Auto-populate website-style Narration
    _updateNarration(contract);
    _fillFromAcceptedBid(contract.id);

    // 2. Fetch Full Contract Details (Deep API call for complete items & logistics)
    try {
      isLoadingDetail.value = true;
      debugPrint("📦 [AdminCreateDCController] Fetching deep contract details from API: /api/mobile/contracts/${contract.id}/");
      final detail = await ContractService.getContractDetail(contract.id);

      debugPrint("✅ [AdminCreateDCController] Deep details loaded successfully!");

      // Update bags and packing weight from deep detail if not already set
      if (detail.bagCount != null && detail.bagCount! > 0) {
        bagCountController.text = detail.bagCount.toString();
      } else if (detail.bags.isNotEmpty) {
        final b = double.tryParse(detail.bags);
        bagCountController.text = b != null ? b.toInt().toString() : detail.bags;
      }

      if (detail.packingWeightKg.isNotEmpty) {
        packingWeightController.text = detail.packingWeightKg;
      }

      if (detail.dealQuantity.isNotEmpty) {
        quantityController.text = detail.dealQuantity;
      }
      if (detail.dealAmount.isNotEmpty) {
        rateController.text = detail.dealAmount;
      }
      if (detail.loadingFrom.isNotEmpty) {
        loadingFromController.text = detail.loadingFrom;
      }
      if (detail.loadingTo.isNotEmpty) {
        loadingToController.text = detail.loadingTo;
      }

      // Update transport details if returned by deep API
      if (detail.transporterName != null && detail.transporterName!.isNotEmpty) {
        transporterNameController.text = detail.transporterName!;
      }
      if (detail.truckNumber != null && detail.truckNumber!.isNotEmpty) {
        truckNumberController.text = detail.truckNumber!;
      }
      if (detail.driverName != null && detail.driverName!.isNotEmpty) {
        driverNameController.text = detail.driverName!;
      }
      if (detail.driverMobile != null && detail.driverMobile!.isNotEmpty) {
        driverPhoneController.text = detail.driverMobile!;
      }
      if (detail.driverLicenseNumber != null && detail.driverLicenseNumber!.isNotEmpty) {
        driverLicenseController.text = detail.driverLicenseNumber!;
      }

      _fillFromAcceptedBid(contract.id);

      _calculateAmount();
      _updateNarration(contract, detail: detail);

      debugPrint("📋 [AdminCreateDCController] Auto-filled state:");
      debugPrint("   Bags: ${bagCountController.text}");
      debugPrint("   Packing: ${packingWeightController.text} kg");
      debugPrint("   Transporter: ${transporterNameController.text}");
      debugPrint("   Truck No: ${truckNumberController.text}");
      debugPrint("   Driver: ${driverNameController.text} (${driverPhoneController.text})");
      debugPrint("   License: ${driverLicenseController.text}");
      debugPrint("   Rate: ₹${rateController.text} | Total Amount: ₹${amountController.text}");
      debugPrint("==================================================================");
    } catch (e) {
      debugPrint("ℹ️ [AdminCreateDCController] Contract detail fetch note (using standard data): $e");
    } finally {
      isLoadingDetail.value = false;
    }
  }

  /// Fills empty transport fields from the accepted bid's truck/driver assignment.
  /// Fields stay empty when the transporter has not assigned yet; the admin types them,
  /// or the backend fills them from the assignment on save.
  void _fillFromAcceptedBid(int contractId) {
    final bid = _acceptedByContract[contractId];
    if (bid == null) return;
    void fill(TextEditingController controller, List<String> keys) {
      if (controller.text.trim().isNotEmpty) return;
      for (final key in keys) {
        final value = (bid[key] ?? '').toString().trim();
        if (value.isNotEmpty) {
          controller.text = value;
          return;
        }
      }
    }

    fill(transporterNameController, const ['transporter_full_name', 'transporter_name']);
    fill(truckNumberController, const ['truck_number']);
    fill(driverNameController, const ['driver_name']);
    fill(driverPhoneController, const ['driver_mobile']);
    fill(driverLicenseController, const ['driver_license']);
  }

  void _calculateAmount() {
    final qty = double.tryParse(quantityController.text.trim()) ?? 0.0;
    final rate = double.tryParse(rateController.text.trim()) ?? 0.0;
    if (qty > 0 && rate > 0) {
      amountController.text = (qty * rate).toStringAsFixed(2);
    }
  }

  void _updateNarration(ContractModel contract, {ContractDetailModel? detail}) {
    final contractCode = detail?.contractId.isNotEmpty == true ? detail!.contractId : contract.contractId;
    final seller = detail?.displaySellerId.isNotEmpty == true
        ? detail!.displaySellerId
        : (contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contract.sellerName);
    final buyer = detail?.displayBuyerId.isNotEmpty == true
        ? detail!.displayBuyerId
        : (contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contract.buyerName);
    final product = detail?.productTitle.isNotEmpty == true ? detail!.productTitle : contract.productTitle;
    final qty = quantityController.text.isNotEmpty ? quantityController.text : contract.dealQuantity;
    final unit = contract.quantityUnit.isNotEmpty ? contract.quantityUnit : "qtl";
    final rate = rateController.text.isNotEmpty ? rateController.text : contract.dealAmount;
    final transporter = transporterNameController.text.isNotEmpty
        ? transporterNameController.text
        : (contract.transporterName ?? "");
    final from = loadingFromController.text.isNotEmpty ? loadingFromController.text : contract.loadingFrom;
    final to = loadingToController.text.isNotEmpty ? loadingToController.text : contract.loadingTo;

    final buffer = StringBuffer();
    buffer.writeln("Selected Contract Details:");
    buffer.writeln("Contract: $contractCode");
    buffer.writeln("Seller: $seller");
    buffer.writeln("Buyer: $buyer");
    buffer.writeln("Product: $product");
    buffer.writeln("Quantity: $qty $unit");
    buffer.writeln("Deal Amount: ₹$rate");
    if (transporter.isNotEmpty) {
      buffer.writeln("Transporter: $transporter");
    }
    if (from.isNotEmpty && to.isNotEmpty) {
      buffer.writeln("Route: $from to $to");
    }

    remarksController.text = buffer.toString().trim();
  }

  void clearSelectedContract() {
    selectedContract.value = null;
    quantityController.clear();
    bagCountController.clear();
    packingWeightController.clear();
    rateController.clear();
    amountController.clear();

    transporterNameController.clear();
    truckNumberController.clear();
    driverNameController.clear();
    driverPhoneController.clear();
    driverLicenseController.clear();

    loadingFromController.clear();
    loadingToController.clear();
    remarksController.clear();
    debugPrint("🧹 [AdminCreateDCController] Selected contract cleared.");
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
    final bags = int.tryParse(bagCountController.text.trim()) ?? 0;

    // 2. Build Payload matching complete website submission
    final payload = {
      "contract_id": contract.id,
      "order": contract.id,
      "seller_name": contract.displaySellerId.isNotEmpty ? contract.displaySellerId : contract.sellerName,
      "buyer_name": contract.displayBuyerId.isNotEmpty ? contract.displayBuyerId : contract.buyerName,
      "product_title": contract.productTitle,
      "transporter_name": transporterNameController.text.trim(),
      "truck_number": truckNo,
      "vehicle_number": truckNo,
      "driver_name": driverName,
      "driver_mobile": driverPhoneController.text.trim(),
      "driver_phone": driverPhoneController.text.trim(),
      "driver_license_number": driverLicenseController.text.trim(),
      "driver_license": driverLicenseController.text.trim(),
      "dispatch_date": dispatchDateController.text.trim(),
      // Backend rule: bags (x packing weight) set the quantity; without bags the quantity is required.
      if (bags > 0) ...{
        "bag_count": bags,
        "packing_weight_kg": packingWeightController.text.trim(),
      } else ...{
        "quantity": double.tryParse(quantityController.text.trim()) ?? 0.0,
        "quantity_unit": contract.quantityUnit.isNotEmpty ? contract.quantityUnit.toLowerCase() : "qtl",
      },
      "rate": double.tryParse(rateController.text.trim()) ?? 0.0,
      "total_amount": double.tryParse(amountController.text.trim()) ?? 0.0,
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
        // 1. Immediately refresh the Challan List in background
        if (Get.isRegistered<AdminDCListController>()) {
          Get.find<AdminDCListController>().fetchChallans(isRefresh: true);
        }

        // 2. Always navigate to the "Delivery Challans" screen where drafts and pending challans are shown
        if (Get.previousRoute == AppRoutes.adminDeliveryChallans) {
          Get.back(result: true);
        } else {
          Get.offNamed(AppRoutes.adminDeliveryChallans);
        }

        // 3. Construct user-friendly success notification from server data
        final challanNo = (result['challan_number'] ?? '').toString();
        final displayTitle = challanNo.isNotEmpty 
            ? "Challan #$challanNo Created!" 
            : "Delivery Challan Created!";
            
        final displayMsg = challanNo.isNotEmpty
            ? "Delivery Challan #$challanNo has been created successfully as Draft."
            : (result['message'] ?? "Delivery Challan generated successfully!");

        Get.snackbar(
          displayTitle,
          displayMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF059669),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          duration: const Duration(seconds: 4),
        );
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
