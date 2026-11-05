import 'package:flutter/foundation.dart';
import '../model/contract_details_model.dart';
import 'package:get/get.dart';
import '../../../services/contract_services.dart';
import '../model/contract_model.dart';
import '../../../utils/app_snackbar.dart';
import '../../../utils/app_preferences.dart';

class ContractController extends GetxController {
  var isLoading = false.obs;
  bool _fetchingContracts = false;

  /// CONTRACT LIST
  var contracts = <ContractModel>[].obs;

  /// CONTRACT DETAIL
  Rxn<ContractDetailModel> contractDetail = Rxn<ContractDetailModel>();

  /// DELIVERY CHALLAN STATUS FOR DETAIL VIEW
  final hasDeliveryChallan = false.obs;
  final deliveryChallanId = Rxn<int>();
  final deliveryChallanNumber = ''.obs;
  final isCheckingChallan = false.obs;
  final userRole = ''.obs;

  @override
  void onInit() {
    _loadUserRole();
    fetchContracts();
    super.onInit();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await AppPreferences.getRole();
      userRole.value = role?.trim().toLowerCase() ?? '';
    } catch (_) {}
  }

  /// ===============================
  /// FETCH CONTRACT LIST
  /// ===============================
  Future<void> fetchContracts({bool silent = false}) async {
    if (_fetchingContracts || isClosed || (silent && isLoading.value)) return;
    _fetchingContracts = true;
    try {
      if (!silent) isLoading.value = true;

      final result = await ContractService.fetchContracts(silent: silent);

      if (!isClosed) contracts.assignAll(result);
    } catch (e) {
      if (!silent && !isClosed) AppSnackbar.snackbar("Error", e.toString());
    } finally {
      _fetchingContracts = false;
      if (!isClosed && !silent) isLoading.value = false;
    }
  }

  /// ===============================
  /// FETCH CONTRACT DETAIL
  /// ===============================
  Future<void> fetchContractDetail(int contractId) async {
    try {
      if (contractDetail.value == null || contractDetail.value!.id != contractId) {
        isLoading.value = true;
        hasDeliveryChallan.value = false;
        deliveryChallanId.value = null;
        deliveryChallanNumber.value = '';
      }
      final result = await ContractService.getContractDetail(contractId);
      contractDetail.value = result;
      await checkDeliveryChallanStatus(result);
    } catch (e) {
      debugPrint("⚠️ [ContractController] fetchContractDetail notice: $e");
      if (contractDetail.value == null) {
        Future.microtask(() {
          AppSnackbar.snackbar(
            "Notice",
            "Contract details unavailable from server.",
            snackPosition: SnackPosition.BOTTOM,
          );
        });
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// CHECK DELIVERY CHALLAN STATUS
  /// ===============================
  Future<void> checkDeliveryChallanStatus(ContractDetailModel contract) async {
    if (contract.hasDeliveryChallan) {
      hasDeliveryChallan.value = true;
      deliveryChallanId.value = contract.deliveryChallanId;
      deliveryChallanNumber.value = contract.deliveryChallanNumber ?? '';
      return;
    }

    if (userRole.value.isEmpty) {
      await _loadUserRole();
    }

    final role = userRole.value;
    final isAdmin = role.isEmpty || const {'admin', 'super_admin', 'sub_admin'}.contains(role);
    if (!isAdmin) {
      hasDeliveryChallan.value = false;
      return;
    }

    try {
      isCheckingChallan.value = true;
      final challan = await ContractService.checkDeliveryChallanExists(
        contractId: contract.id,
        contractCode: contract.contractId,
        interestId: contract.interestId,
      );
      if (challan != null) {
        hasDeliveryChallan.value = true;
        deliveryChallanId.value = challan['id'] is int
            ? challan['id'] as int
            : int.tryParse(challan['id']?.toString() ?? '');
        deliveryChallanNumber.value = (challan['challan_number'] ?? '').toString();
      } else {
        hasDeliveryChallan.value = false;
        deliveryChallanId.value = null;
        deliveryChallanNumber.value = '';
      }
    } catch (e) {
      debugPrint("⚠️ [ContractController] checkDeliveryChallanStatus error: $e");
    } finally {
      isCheckingChallan.value = false;
    }
  }

  /// ===============================
  /// UPDATE CONTRACT STATUS
  /// ===============================
  Future<bool> updateContractStatus({
    required int contractId,
    required String status,
    required String adminRemark,
  }) async {
    try {
      isLoading.value = true;

      await ContractService.updateContractStatus(
        contractId: contractId,
        status: status,
        adminRemark: adminRemark,
      );

      AppSnackbar.snackbar("Success", "Contract updated successfully");

      await fetchContracts();
      await fetchContractDetail(contractId);
      return true;
    } catch (e) {
      Future.microtask(() {
        AppSnackbar.snackbar("Error", e.toString());
      });
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// DELETE CONTRACT
  /// ===============================
  Future<void> deleteContract(int contractId) async {
    try {
      isLoading.value = true;

      final response = await ContractService.deleteContract(contractId);
      contracts.removeWhere((c) => c.id == contractId);
      AppSnackbar.snackbar("Success", response["message"] ?? "Contract deleted");
    } catch (e) {
      Future.microtask(() {
        AppSnackbar.snackbar("Error", e.toString());
      });
    } finally {
      isLoading.value = false;
    }
  }
}
