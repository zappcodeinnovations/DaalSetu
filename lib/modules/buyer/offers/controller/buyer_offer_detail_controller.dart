import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
import 'package:get/get.dart';

class BuyerOfferDetailController extends GetxController {
  var isLoading = true.obs;
  var isSending = false.obs;
  var offerDetails = Rxn<Map<String, dynamic>>();

  Future<void> fetchDetails(int id, {bool silent = false}) async {
    try {
      if (!silent) isLoading(true);
      final data = await BuyerServices.getOfferDetails(id);
      offerDetails.value = data;
    } catch (e) {
      if (!silent) {
        AppSnackbar.showError(title: "Error", message: "Could not fetch offer details");
      }
    } finally {
      if (!silent) isLoading(false);
    }
  }

  Future<void> sendQuoteMessage({
    required dynamic rfqId,
    required dynamic quotationId,
    required String message,
    dynamic counterPrice,
    dynamic counterQuantity,
    dynamic bagCount,
    dynamic packingWeightKg,
  }) async {
    try {
      isSending(true);
      final res = await BuyerServices.sendBuyerRequirementMessage(
        rfqId: rfqId,
        quotationId: quotationId,
        message: message,
        counterPrice: counterPrice,
        counterQuantity: counterQuantity,
        bagCount: bagCount,
        packingWeightKg: packingWeightKg,
      );
      AppSnackbar.showSuccess(
        title: "Sent",
        message: res['message'] ?? "Counter proposal sent successfully",
      );
      final numId = int.tryParse(rfqId.toString()) ?? 0;
      if (numId > 0) {
        await fetchDetails(numId, silent: true);
      }
    } catch (e) {
      AppSnackbar.showError(title: "Failed", message: e.toString().replaceAll("Exception: ", ""));
    } finally {
      isSending(false);
    }
  }

  Future<void> cancelOffer(int id) async {
    try {
      isLoading(true);
      await BuyerServices.cancelOffer(id);
      AppSnackbar.showSuccess(title: "Success", message: "Requirement cancelled successfully");
      fetchDetails(id);
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: e.toString());
    } finally {
      isLoading(false);
    }
  }
}
