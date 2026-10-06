import '../model/delivery_challan_model.dart';
import '../../../../services/seller_services.dart';
import 'package:get/get.dart';

class SellerDeliveryController extends GetxController {
  var isLoading = true.obs;
  var isDetailLoading = false.obs;
  var challans = <SellerChallanModel>[].obs;
  var selectedChallan = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchChallans();
  }

  Future<void> fetchChallans() async {
    try {
      isLoading(true);
      final data = await SellerServices.getDeliveryChallans();
      challans.assignAll(data.map((e) => SellerChallanModel.fromJson(e)).toList());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchChallanDetails(int id) async {
    try {
      isDetailLoading(true);
      final data = await SellerServices.getChallanDetails(id);
      // API wraps the challan as {"success": true, "data": {...}}.
      selectedChallan.value = data['data'] is Map<String, dynamic> ? data['data'] : data;
    } catch (e) {
      Get.snackbar("Error", "Could not fetch details");
    } finally {
      isDetailLoading(false);
    }
  }

  Future<void> dispatchChallan(int id) async {
    try {
      isLoading(true);
      await SellerServices.dispatchChallan(id);
      Get.snackbar("Success", "Shipment marked as dispatched");
      
      // Refresh list and details if open
      fetchChallans();
      if (selectedChallan.value != null && selectedChallan.value!['id'] == id) {
        fetchChallanDetails(id);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }
}
