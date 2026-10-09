import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import '../model/seller_rfq_model.dart';
import 'package:daalsetu/utils/global_error_handler.dart';

/// Incoming buyer requirements list (single API: /api/buyer-requirements/?tab=incoming).
class SellerRfqController extends GetxController {
  var isLoading = false.obs;
  var rfqList = <SellerRfqModel>[].obs;
  var searchQuery = ''.obs;
  var statusFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRFQs();
    // Search only after the user stops typing for a moment.
    debounce(searchQuery, (_) => fetchRFQs(), time: const Duration(milliseconds: 400));
  }

  Future<void> fetchRFQs() async {
    try {
      isLoading.value = true;
      final data = await SellerServices.getBuyerRequirements(
        tab: 'incoming',
        search: searchQuery.value,
        status: statusFilter.value == 'all' ? null : statusFilter.value,
      );
      rfqList.value = (data['results'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SellerRfqModel.fromJson)
          .toList();
    } catch (e) {
      SellerUi.error(e);
    } finally {
      isLoading.value = false;
    }
  }

  void setStatus(String status) {
    statusFilter.value = status;
    fetchRFQs();
  }
}

/// One requirement + the seller's own negotiation thread.
class SellerRfqDetailController extends GetxController {
  final String rfqId;
  SellerRfqDetailController(this.rfqId);

  var isLoading = true.obs;
  final rfq = Rxn<SellerRfqModel>();
  final thread = Rxn<SellerQuotationModel>();
  Timer? _refreshTimer;
  bool _refreshInProgress = false;

  @override
  void onInit() {
    super.onInit();
    load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (AppForeground.isActive) load(silent: true);
    });
  }

  Future<void> load({bool silent = false}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      if (!silent) isLoading(true);
      final data = await SellerServices.getBuyerRequirement(rfqId, silent: silent);
      final loaded = SellerRfqModel.fromJson(data['data'] as Map<String, dynamic>);
      rfq.value = loaded;
      if (loaded.myQuotationId != null) {
        final threadData = await SellerServices.getBuyerRequirement(rfqId, quotationId: loaded.myQuotationId, silent: silent);
        thread.value = SellerQuotationModel.fromJson(threadData['data'] as Map<String, dynamic>);
      } else {
        thread.value = null;
      }
    } catch (e) {
      if (!silent) SellerUi.error(e);
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

  Future<void> _act(Map<String, dynamic> body) async {
    final result = await SellerUi.run(() => SellerServices.buyerRequirementAction(rfqId, body));
    if (result != null) {
      await load();
      if (Get.isRegistered<SellerRfqController>()) Get.find<SellerRfqController>().fetchRFQs();
    }
  }

  Future<void> submitQuote({
    required String price,
    required String quantity,
    String? bagCount,
    String? packingWeight,
    String? deliveryTerms,
    String? remark,
  }) =>
      _act({
        "action": "quote",
        "offered_price": price,
        "offered_quantity": quantity,
        if (bagCount != null && bagCount.isNotEmpty) "offered_bag_count": bagCount,
        if (packingWeight != null && packingWeight.isNotEmpty) "packing_weight_kg": packingWeight,
        if (deliveryTerms != null && deliveryTerms.isNotEmpty) "delivery_terms": deliveryTerms,
        if (remark != null && remark.isNotEmpty) "seller_remark": remark,
      });

  Future<void> sendMessage({String? counterPrice, String? counterQuantity, String? bagCount, String? packingWeight}) {
    final quotationId = thread.value?.id;
    if (quotationId == null) return Future.value();
    return _act({
      "action": "message",
      "quotation_id": quotationId,
      if (counterPrice != null && counterPrice.isNotEmpty) "counter_price": counterPrice,
      if (counterQuantity != null && counterQuantity.isNotEmpty) "counter_quantity": counterQuantity,
      if (bagCount != null && bagCount.isNotEmpty) "counter_bag_count": bagCount,
      if (packingWeight != null && packingWeight.isNotEmpty) "packing_weight_kg": packingWeight,
    });
  }

  Future<void> accept() async {
    final quotationId = thread.value?.id;
    if (quotationId == null) return;
    if (await SellerUi.confirm("Accept Offer", "Accept the buyer's latest offer? The deal moves to admin confirmation.", confirmText: "Accept")) {
      await _act({"action": "accept", "quotation_id": quotationId});
    }
  }

  Future<void> reject() async {
    final quotationId = thread.value?.id;
    if (quotationId == null) return;
    if (await SellerUi.confirm("Withdraw Quotation", "Withdraw your quotation for this requirement?", confirmText: "Withdraw", color: Colors.red)) {
      await _act({"action": "reject", "quotation_id": quotationId});
    }
  }
}
