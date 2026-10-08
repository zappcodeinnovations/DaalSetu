import 'package:flutter/foundation.dart';
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

    debugPrint("=== CONTRACT API RESPONSE ===");
    debugPrint("$response");
    debugPrint("=============================");

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid contract response");
    }

    final List results = response["results"] ?? [];

    return results.map((e) => ContractModel.fromJson(e)).toList();
  }

  /// ===============================
  /// FETCH CONTRACT DETAILS
  /// ===============================
  static Future<ContractDetailModel> getContractDetail(int contractId) async {
    final response = await ApiClient.get(
      endpoint: "${ApiUrls.contracts}$contractId/",
      requireAuth: true,
    );

    debugPrint("=== CONTRACT DETAIL API RESPONSE (ID: $contractId) ===");
    debugPrint("$response");
    debugPrint("==========================================================");

    if (response == null || response is! Map<String, dynamic>) {
      throw Exception("Invalid contract detail response");
    }

    final data = response["data"] ?? response;
    if (data is! Map<String, dynamic>) {
      throw Exception("Invalid contract detail data");
    }

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
      data: {"status": status, "admin_remark": adminRemark},
      requireAuth: true,
    );

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

    return response;
  }
}
