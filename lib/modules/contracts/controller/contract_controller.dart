import 'package:flutter/foundation.dart';
import '../model/contract_details_model.dart';
import 'package:get/get.dart';
import '../../../services/contract_services.dart';
import '../model/contract_model.dart';
import '../../../utils/app_snackbar.dart';

class ContractController extends GetxController {
  var isLoading = false.obs;

  /// CONTRACT LIST
  var contracts = <ContractModel>[].obs;

  /// CONTRACT DETAIL
  Rxn<ContractDetailModel> contractDetail = Rxn<ContractDetailModel>();

  @override
  void onInit() {
    fetchContracts();
    super.onInit();
  }

  /// ===============================
  /// FETCH CONTRACT LIST
  /// ===============================
  Future<void> fetchContracts() async {
    try {
      isLoading.value = true;

      final result = await ContractService.fetchContracts();

      contracts.assignAll(result);
    } catch (e) {
      AppSnackbar.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// FETCH CONTRACT DETAIL
  /// ===============================
  Future<void> fetchContractDetail(int contractId) async {
    try {
      if (contractDetail.value == null || contractDetail.value!.id != contractId) {
        isLoading.value = true;
      }
      final result = await ContractService.getContractDetail(contractId);
      contractDetail.value = result;
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
