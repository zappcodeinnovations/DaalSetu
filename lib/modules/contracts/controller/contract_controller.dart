import 'package:agro_broker/modules/contracts/model/contract_details_model.dart';
import 'package:get/get.dart';
import 'package:agro_broker/services/contract_services.dart';
import '../model/contract_model.dart';

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
      Get.snackbar("Success", "Contract updated successfully");
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// FETCH CONTRACT DETAIL
  /// ===============================
  Future<void> fetchContractDetail(int contractId) async {
    try {
      isLoading.value = true;

      final result = await ContractService.getContractDetail(contractId);

      contractDetail.value = result;
    } catch (e) {
      Future.microtask(() {
        Get.snackbar("Error", e.toString());
      });
    } finally {
      isLoading.value = false;
    }
  }

  /// ===============================
  /// UPDATE CONTRACT STATUS
  /// ===============================
  Future<void> updateContractStatus({
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

      Get.snackbar("Success", "Contract updated successfully");

      await fetchContracts();
    } catch (e) {
      Future.microtask(() {
        Get.snackbar("Error", e.toString());
      });
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

      if (response["success"] == true) {
        contracts.removeWhere((c) => c.id == contractId);

        Get.snackbar("Success", response["message"] ?? "Contract deleted");
      }
    } catch (e) {
      Future.microtask(() {
        Get.snackbar("Error", e.toString());
      });
    } finally {
      isLoading.value = false;
    }
  }
}
