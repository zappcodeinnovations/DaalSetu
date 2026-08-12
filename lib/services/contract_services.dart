import '../comman/api_url.dart';
import '../modules/contracts/model/contract_details_model.dart';
import '../modules/contracts/model/contract_model.dart';
import '../network/api_client.dart';

class ContractService {

  /// ===============================
  /// FETCH CONTRACT LIST
  /// ===============================
  static Future<List<ContractModel>> fetchContracts() async {

    final response = await ApiClient.get(
      endpoint: ApiUrls.contracts,
      requireAuth: true,
    );

    print("=== CONTRACT API RESPONSE ===");
    print(response);
    print("=============================");

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid contract response");
    }

    final List results = response["results"] ?? [];

    return results
        .map((e) => ContractModel.fromJson(e))
        .toList();
  }


  /// ===============================
  /// FETCH CONTRACT DETAILS
  /// ===============================
  static Future<ContractDetailModel> getContractDetail(int contractId) async {

    final response = await ApiClient.get(
      endpoint: "${ApiUrls.contracts}$contractId/",
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid contract detail response");
    }

    final data = response["data"];

    return ContractDetailModel.fromJson(data);
  }


  /// ===============================
  /// UPDATE CONTRACT STATUS
  /// ===============================
  static Future<Map<String, dynamic>> updateContractStatus({
    required int contractId,
    required String status,
    required String adminRemark,
  }) async {

    final response = await ApiClient.patch(
      endpoint: "${ApiUrls.contracts}$contractId/",
      data: {
        "status": status,
        "admin_remark": adminRemark,
      },
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to update contract");
    }

    return response;
  }


  /// ===============================
  /// DELETE CONTRACT
  /// ===============================
  static Future<Map<String, dynamic>> deleteContract(int contractId) async {

    final response = await ApiClient.delete(
      endpoint: "${ApiUrls.contracts}$contractId/",
      requireAuth: true,
    );

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Failed to delete contract");
    }

    return response;
  }
}
