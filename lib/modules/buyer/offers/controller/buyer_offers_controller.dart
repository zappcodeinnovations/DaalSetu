import 'package:agro_broker/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:agro_broker/network/api_client.dart';
import 'package:agro_broker/services/buyer_services.dart';
import 'package:get/get.dart';

class BuyerOffersController extends GetxController {
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;

  var offersList = <BuyerOfferModel>[].obs;

  // The type of offers to fetch (e.g., 'all', 'today', 'pending', 'previous', 'interests')
  final String offerType;

  BuyerOffersController({required this.offerType});

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      isLoading(true);
      isError(false);
      offersList.clear();

      List<dynamic> data;

      switch (offerType) {
        case 'today':
          data = await BuyerServices.getTodayOffers();
          break;
        case 'pending':
          data = await BuyerServices.getPendingOffers();
          break;
        case 'previous':
          data = await BuyerServices.getPreviousOffers();
          break;
        case 'interests':
          data = await BuyerServices.getMyInterests();
          break;
        case 'all':
        default:
          data = await BuyerServices.getOffers();
          break;
      }

      offersList.value = data.map((e) => BuyerOfferModel.fromJson(e)).toList();
    } catch (e) {
      isError(true);
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> approveInterest(int productId, int interestId, String remark) async {
    try {
      isLoading(true);
      await ApiClient.post(
        endpoint: "/api/offers/$productId/approve/",
        body: {"interest_id": interestId, "remark": remark},
        requireAuth: true,
      );
      Get.snackbar("Success", "Interest approved");
      fetchOffers();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> confirmDeal(int productId, int interestId, String remark) async {
    try {
      isLoading(true);
      await ApiClient.post(
        endpoint: "/api/offers/$productId/buyer-confirm/",
        body: {"interest_id": interestId, "remark": remark},
        requireAuth: true,
      );
      Get.snackbar("Success", "Deal confirmed successfully");
      fetchOffers();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> rejectInterest(int productId, int interestId, String remark) async {
    try {
      isLoading(true);
      await BuyerServices.rejectOffer(productId, interestId, remark);
      Get.snackbar("Interest Rejected", "The seller has been notified.");
      fetchOffers();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }
}
