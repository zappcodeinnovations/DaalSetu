import '../../../../services/buyer_services.dart';
import '../../../../services/product_services.dart';
import '../../../../utils/app_snackbar.dart';
import 'package:get/get.dart';

class BuyerOfferDetailController extends GetxController {
  var isLoading = true.obs;
  var isSending = false.obs;
  var offerDetails = Rxn<Map<String, dynamic>>();
  var negotiationThread = Rxn<Map<String, dynamic>>();
  bool _fetchInProgress = false;

  Future<void> loadNegotiationThread(int productId, int interestId) async {
    try {
      final res = await BuyerServices.getOfferInterestThread(
        productId,
        interestId,
      );
      final raw = res['data'];
      if (raw is Map) {
        final thread = Map<String, dynamic>.from(raw);

        // 1. Unpack nested product or offer details map if returned by API
        final productMap = (thread['product'] is Map ? thread['product'] : null) ??
            (thread['offer'] is Map ? thread['offer'] : null) ??
            (thread['product_detail'] is Map ? thread['product_detail'] : null);
        if (productMap != null) {
          thread['seller_price'] ??= productMap['amount'] ?? productMap['seller_price'] ?? productMap['price'];
          thread['available_quantity'] ??= productMap['available_quantity'] ?? productMap['remaining_quantity'] ?? productMap['stock_quantity'] ?? productMap['quantity'];
          thread['price_unit'] ??= productMap['amount_unit'] ?? productMap['price_unit'];
          thread['quantity_unit'] ??= productMap['quantity_unit'];
        }

        // 2. Map snapshot operational fields directly from API response
        thread['seller_price'] ??= thread['seller_snapshot_amount'];
        thread['available_quantity'] ??= thread['seller_snapshot_quantity'];

        // 3. Fallback to parent offerDetails if present in controller
        final details = offerDetails.value;
        if (details != null) {
          thread['seller_price'] ??= details['target_price'] ?? details['amount'] ?? details['price'] ?? details['seller_price'] ?? details['seller_snapshot_amount'];
          thread['available_quantity'] ??= details['available_quantity'] ?? details['remaining_quantity'] ?? details['seller_snapshot_quantity'] ?? details['original_quantity'] ?? details['quantity'];
          thread['price_unit'] ??= details['price_unit'] ?? details['amount_unit'] ?? details['unit'];
          thread['quantity_unit'] ??= details['quantity_unit'] ?? details['unit'];
        }

        // 4. Fallback to ProductService if still missing numeric seller price or operational quantity
        if (productId > 0 &&
            (thread['seller_price'] == null ||
                thread['seller_price'].toString().trim().isEmpty ||
                thread['seller_price'] == '-' ||
                thread['available_quantity'] == null ||
                thread['available_quantity'].toString().trim().isEmpty ||
                thread['available_quantity'] == '-')) {
          try {
            final productDetail = await ProductService.getProductDetail(productId);
            if (productDetail.amount.isNotEmpty) {
              thread['seller_price'] ??= productDetail.amount;
            }
            final qty = productDetail.availableQuantity.isNotEmpty
                ? productDetail.availableQuantity
                : productDetail.remainingQuantity;
            if (qty.isNotEmpty) {
              thread['available_quantity'] ??= qty;
            }
            if (thread['price_unit'] == null || thread['price_unit'].toString().isEmpty) {
              thread['price_unit'] = productDetail.amountUnit.isNotEmpty ? productDetail.amountUnit : 'TON';
            }
            if (thread['quantity_unit'] == null || thread['quantity_unit'].toString().isEmpty) {
              thread['quantity_unit'] = productDetail.quantityUnit.isNotEmpty ? productDetail.quantityUnit : 'QTL';
            }
          } catch (_) {}
        }

        negotiationThread.value = thread;
      }
    } catch (_) {}
  }

  Future<bool> confirmOfferInterest({
    required int productId,
    required int interestId,
    String remark = '',
  }) async {
    try {
      isSending(true);
      final res = await BuyerServices.confirmOfferInterest(
        productId,
        interestId,
        remark: remark,
      );
      AppSnackbar.showSuccess(
        title: "Accepted",
        message: res['message'] ?? "Offer accepted successfully",
      );
      await loadNegotiationThread(productId, interestId);
      return true;
    } catch (e) {
      AppSnackbar.showError(
        title: "Failed",
        message: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    } finally {
      isSending(false);
    }
  }

  Future<bool> rejectOfferInterest({
    required int productId,
    required int interestId,
    String remark = '',
  }) async {
    try {
      isSending(true);
      final res = await BuyerServices.rejectOfferInterest(
        productId,
        interestId,
        remark: remark,
      );
      AppSnackbar.showSuccess(
        title: "Rejected",
        message: res['message'] ?? "Offer rejected successfully",
      );
      await loadNegotiationThread(productId, interestId);
      return true;
    } catch (e) {
      AppSnackbar.showError(
        title: "Failed",
        message: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    } finally {
      isSending(false);
    }
  }

  Future<void> fetchDetails(
    int id, {
    bool silent = false,
    bool preferBuyerOffer = false,
    bool preferBuyerRequirement = false,
    int? productId,
    int? interestId,
  }) async {
    if (_fetchInProgress) return;
    _fetchInProgress = true;
    try {
      if (!silent) isLoading(true);
      final data = preferBuyerOffer
          ? await BuyerServices.getBuyerOfferDetails(id)
          : preferBuyerRequirement
          ? await BuyerServices.getBuyerRequirementDetails(id)
          : await BuyerServices.getOfferDetails(id);
      offerDetails.value = data;

      final pId =
          productId ??
          int.tryParse(
            (data['product_id'] ??
                    data['product']?['id'] ??
                    (data['is_interest'] == true ? data['id'] : null) ??
                    '')
                .toString(),
          );
      final iId =
          interestId ??
          int.tryParse(
            (data['interest_id'] ??
                    data['interest']?['id'] ??
                    (data['is_interest'] == true
                        ? data['interest_id']
                        : null) ??
                    '')
                .toString(),
          );

      if (pId != null && pId > 0 && iId != null && iId > 0) {
        await loadNegotiationThread(pId, iId);
      }
    } catch (e) {
      if (!silent) {
        AppSnackbar.showError(
          title: "Error",
          message: "Could not fetch offer details",
        );
      }
    } finally {
      if (!silent) isLoading(false);
      _fetchInProgress = false;
    }
  }

  Future<void> sendQuoteMessage({
    required dynamic rfqId,
    required dynamic quotationId,
    dynamic counterPrice,
    dynamic counterQuantity,
    dynamic bagCount,
    dynamic packingWeightKg,
    int? reloadDetailId,
    bool preferBuyerRequirement = false,
  }) async {
    try {
      isSending(true);
      final res = await BuyerServices.sendBuyerRequirementMessage(
        rfqId: rfqId,
        quotationId: quotationId,
        counterPrice: counterPrice,
        counterQuantity: counterQuantity,
        bagCount: bagCount,
        packingWeightKg: packingWeightKg,
      );
      AppSnackbar.showSuccess(
        title: "Sent",
        message: res['message'] ?? "Counter proposal sent successfully",
      );
      if (reloadDetailId != null && reloadDetailId > 0) {
        await fetchDetails(
          reloadDetailId,
          silent: true,
          preferBuyerRequirement: preferBuyerRequirement,
        );
      }
    } catch (e) {
      AppSnackbar.showError(
        title: "Failed",
        message: e.toString().replaceAll("Exception: ", ""),
      );
    } finally {
      isSending(false);
    }
  }

  Future<void> cancelOffer(int id) async {
    try {
      isLoading(true);
      await BuyerServices.cancelOffer(id);
      AppSnackbar.showSuccess(
        title: "Success",
        message: "Requirement cancelled successfully",
      );
      fetchDetails(id);
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: e.toString());
    } finally {
      isLoading(false);
    }
  }
}
