import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
import 'package:get/get.dart';

class BuyerOfferDetailController extends GetxController {
  var isLoading = true.obs;
  var offerDetails = Rxn<Map<String, dynamic>>();

  Future<void> fetchDetails(int id) async {
    try {
      isLoading(true);
      final data = await BuyerServices.getOfferDetails(id);
      offerDetails.value = data;
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: "Could not fetch offer details");
    } finally {
      isLoading(false);
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
