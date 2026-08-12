import '../model/seller_contract_model.dart';
import '../../../../services/seller_services.dart';
import 'package:get/get.dart';

class SellerContractController extends GetxController {
  var isLoading = true.obs;
  var contracts = <SellerContractModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchContracts();
  }

  Future<void> fetchContracts() async {
    try {
      isLoading(true);
      final data = await SellerServices.getContracts();
      contracts.assignAll(data.map((e) => SellerContractModel.fromJson(e)).toList());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }
}
