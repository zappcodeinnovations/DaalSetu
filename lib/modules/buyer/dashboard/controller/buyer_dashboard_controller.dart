import '../model/buyer_dashboard_model.dart';
import '../../../../services/buyer_services.dart';
import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../services/category_services.dart';
import '../../../category/model/category_model.dart';

class BuyerDashboardController extends GetxController {
  var isLoading = true.obs;
  var isError = false.obs;
  var errorMessage = ''.obs;

  Rx<BuyerDashboardModel?> dashboardData = Rx<BuyerDashboardModel?>(null);
  var categories = <CategoryModel>[].obs;
  var isSearching = false.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final isInitialLoad = dashboardData.value == null;
    try {
      if (isInitialLoad) isLoading(true);
      isError(false);
      errorMessage('');

      final data = await BuyerServices.getDashboard();

      // If the API nests it in a body key, we extract it.
      final actualData = data.containsKey('body') ? data['body'] : data;
      if (actualData is! Map) {
        throw const FormatException('Invalid buyer dashboard response');
      }

      dashboardData.value = BuyerDashboardModel.fromJson(
        Map<String, dynamic>.from(actualData),
      );
    } catch (e) {
      isError(true);
      errorMessage(ApiClient.userFriendlyErrorMessage(e.toString()));
    } finally {
      isLoading(false);
    }

    // Categories are independent of dashboard analytics. A dashboard API
    // failure must not stop this section from refreshing.
    try {
      final cats = await CategoryService.fetchBuyerCategories();
      categories.assignAll(cats);
    } catch (_) {
      // Keep the existing category list on a transient request failure.
    }
  }
}
