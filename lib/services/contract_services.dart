import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../comman/api_url.dart';
import '../modules/contracts/model/contract_details_model.dart';
import '../modules/contracts/model/contract_model.dart';
import '../network/api_client.dart';

class ContractService {
  /// ===============================
  /// FETCH CONTRACT LIST
  /// ===============================
  static Future<List<ContractModel>> fetchContracts({bool silent = false}) async {
    final response = await ApiClient.get(
      endpoint: ApiUrls.contracts,
      requireAuth: true,
      suppressErrorDialog: silent,
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
    dynamic response;
    try {
      response = await ApiClient.get(
        endpoint: "${ApiUrls.contracts}$contractId/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (e) {
      debugPrint("⚠️ [ContractService] Mobile contract $contractId detail error: $e");
      // Check if the contract is already present in the contracts list
      try {
        final list = await fetchContracts();
        final match = list.firstWhereOrNull((c) => c.id == contractId);
        if (match != null) {
          return ContractDetailModel.fromContractModel(match);
        }
      } catch (_) {}
      rethrow;
    }

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
  /// CHECK IF DELIVERY CHALLAN EXISTS FOR CONTRACT
  /// ===============================
  static Future<Map<String, dynamic>?> checkDeliveryChallanExists({
    required int contractId,
    String? contractCode,
    int? interestId,
  }) async {
    final search = (contractCode != null && contractCode.trim().isNotEmpty)
        ? contractCode.trim()
        : contractId.toString();

    try {
      final response = await ApiClient.get(
        endpoint: "${ApiUrls.adminDeliveryChallans}?search=${Uri.encodeComponent(search)}",
        requireAuth: true,
        suppressErrorDialog: true,
      );

      if (response == null || response is! Map<String, dynamic>) {
        return null;
      }

      final List results = response["results"] is List
          ? response["results"] as List
          : (response["data"] is List ? response["data"] as List : []);

      for (final item in results) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        final cCode = (map['contract_code'] ?? map['contract_id_display'] ?? '').toString().trim();
        final cId = map['contract_id'] is int
            ? map['contract_id'] as int
            : int.tryParse(map['contract_id']?.toString() ?? '');
        final orderId = map['order'] is int
            ? map['order'] as int
            : (map['order_id'] is int
                ? map['order_id'] as int
                : int.tryParse((map['order'] ?? map['order_id'])?.toString() ?? ''));

        final matchesContract = (contractCode != null &&
                contractCode.isNotEmpty &&
                cCode.toLowerCase() == contractCode.toLowerCase()) ||
            (cId != null && cId == contractId) ||
            (interestId != null && orderId != null && orderId == interestId);

        final status = (map['status'] ?? '').toString().trim().toLowerCase();
        // Any non-cancelled delivery challan means a challan has already been created for this contract
        if (matchesContract && status != 'cancelled') {
          return map;
        }
      }
    } catch (e) {
      debugPrint("ℹ️ [ContractService] checkDeliveryChallanExists note: $e");
    }
    return null;
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
