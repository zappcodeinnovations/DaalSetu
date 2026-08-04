import 'package:agro_broker/services/buyer_services.dart';
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
      Get.snackbar("Error", "Could not fetch offer details");
    } finally {
      isLoading(false);
    }
  }

  Future<void> cancelOffer(int id) async {
    try {
      isLoading(true);
      await BuyerServices.cancelOffer(id);
      Get.snackbar("Success", "Requirement cancelled successfully");
      fetchDetails(id);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }
}
