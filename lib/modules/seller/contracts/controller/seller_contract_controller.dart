import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_contract_model.dart';
import '../../../../utils/app_snackbar.dart';

class SellerContractController extends GetxController {
  var isLoading = false.obs;
  var contractsList = <SellerContractModel>[].obs;
  bool _fetchingContracts = false;
  List<SellerContractModel> get contracts => contractsList;

  @override
  void onInit() {
    super.onInit();
    fetchContracts();
  }

  Future<void> fetchContracts({bool silent = false}) async {
    if (_fetchingContracts || isClosed) return;
    _fetchingContracts = true;
    try {
      if (!silent) isLoading.value = true;
      final data = await SellerServices.getSellerContracts(silent: silent);
      if (isClosed) return;
      contractsList.value = data.map((e) => SellerContractModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (!silent && !isClosed) AppSnackbar.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      _fetchingContracts = false;
      if (!isClosed && !silent) isLoading.value = false;
    }
  }
}
