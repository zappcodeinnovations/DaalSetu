import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
import 'package:get/get.dart';

class BuyerOfferDetailController extends GetxController {
  var isLoading = true.obs;
  var isSending = false.obs;
  var offerDetails = Rxn<Map<String, dynamic>>();

  Future<void> fetchDetails(
    int id, {
    bool silent = false,
    bool preferBuyerOffer = false,
    bool preferBuyerRequirement = false,
  }) async {
    try {
      if (!silent) isLoading(true);
      final data = preferBuyerOffer
          ? await BuyerServices.getBuyerOfferDetails(id)
          : preferBuyerRequirement
          ? await BuyerServices.getBuyerRequirementDetails(id)
          : await BuyerServices.getOfferDetails(id);
      offerDetails.value = data;
    } catch (e) {
      if (!silent) {
        AppSnackbar.showError(
          title: "Error",
          message: "Could not fetch offer details",
        );
      }
    } finally {
      if (!silent) isLoading(false);
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
