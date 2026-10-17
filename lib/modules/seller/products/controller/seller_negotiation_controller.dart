import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/utils/global_error_handler.dart';
import '../model/offer_interest_model.dart';
import '../../contracts/view/seller_contract_detail_view.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

class SellerNegotiationController extends GetxController {
  final int productId;
  SellerNegotiationController({required this.productId});

  var isLoading = true.obs;
  var interestsList = <OfferInterestModel>[].obs;
  var productData = Rxn<Map<String, dynamic>>();
  Timer? _refreshTimer;
  bool _refreshInProgress = false;

  @override
  void onInit() {
    super.onInit();
    fetchInterests();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (AppForeground.isActive) fetchInterests(silent: true);
    });
  }

  Future<void> fetchInterests({bool silent = false}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      if (!silent) isLoading(true);
      final response = await SellerServices.getOfferInterests(productId);
      if (response['success'] == true) {
        if (response['product'] is Map<String, dynamic>) {
          productData.value = response['product'];
        }
        final list = (response['interests'] as List?) ?? [];
        interestsList.value = list
            .map((e) => OfferInterestModel.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (!silent) SellerUi.error("Could not fetch offer interests: $e");
    } finally {
      if (!silent) isLoading(false);
      _refreshInProgress = false;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> sendCounterOffer({
    required int interestId,
    required String counterPrice,
    required String counterQuantity,
    int? counterBagCount,
    String? counterPackingWeightKg,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.sendCounterOfferMessage(
        productId,
        interestId,
        counterPrice: counterPrice,
        counterQuantity: counterQuantity,
        counterBagCount: counterBagCount,
        counterPackingWeightKg: counterPackingWeightKg,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      if (res['success'] == true) {
        SellerUi.success(res['message'] ?? "Counter offer sent");
        fetchInterests();
      } else {
        SellerUi.error(res['message'] ?? "Failed to send counter offer");
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      SellerUi.error(e);
    }
  }

  /// Seller accepts the buyer's interest (interested -> seller_confirmed); admin confirms the deal later.
  Future<void> approveInterest(int interestId) async {
    final confirmed = await SellerUi.confirm(
      'Accept buyer interest?',
      'This will send the buyer interest for the next confirmation step.',
      confirmText: 'Accept',
      color: Colors.green,
      primaryFirst: true,
    );
    if (!confirmed) return;
    final result = await SellerUi.run(
      () => SellerServices.approveBuyerInterest(productId, interestId),
    );
    if (result != null) fetchInterests();
  }

  Future<void> rejectInterest(int interestId) async {
    final confirmed = await SellerUi.confirm(
      'Reject buyer interest?',
      'This action cannot be undone.',
      confirmText: 'Reject',
      color: Colors.red,
      primaryFirst: true,
    );
    if (!confirmed) return;
    final result = await SellerUi.run(
      () => SellerServices.rejectBuyerInterest(productId, interestId),
    );
    if (result != null) fetchInterests();
  }

  Future<void> confirmDeal(int interestId, {String? adminRemark}) async {
    bool dialogShown = false;
    try {
      Get.dialog(
        const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: false,
      );
      dialogShown = true;

      final res = await SellerServices.confirmOfferDeal(
        productId,
        interestId,
        adminRemark: adminRemark,
      );

      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) Get.back();
      }

      if (res['success'] == true) {
        SellerUi.success(res['message'] ?? "Deal confirmed successfully!");

        // Check if contract ID was returned
        final rawContractId =
            res['contract_id'] ??
            res['data']?['contract_id'] ??
            res['contract']?['id'] ??
            res['data']?['id'];
        final contractId = rawContractId is int
            ? rawContractId
            : int.tryParse(rawContractId?.toString() ?? '');

        if (contractId != null && contractId > 0) {
          Get.to(() => SellerContractDetailView(contractId: contractId));
        } else {
          fetchInterests();
        }
      } else {
        SellerUi.error(res['message'] ?? "Failed to confirm deal");
      }
    } catch (e) {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) Get.back();
      }
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      SellerUi.error(msg.isNotEmpty ? msg : "Failed to confirm deal");
    } finally {
      if (dialogShown) {
        dialogShown = false;
        if (Get.isDialogOpen ?? false) Get.back();
      }
    }
  }
}
