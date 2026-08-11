import 'package:daalsetu/modules/seller/dashboard/model/seller_dashboard_model.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:get/get.dart';

class SellerDashboardController extends GetxController {
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;

  Rx<SellerDashboardModel?> dashboardData = Rx<SellerDashboardModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading(true);
      isError(false);

      final data = await SellerServices.getDashboard();
      dashboardData.value = SellerDashboardModel.fromJson(data);

    } catch (e) {
      isError(true);
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }
}
