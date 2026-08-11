import 'package:daalsetu/modules/buyer/dashboard/model/buyer_dashboard_model.dart';
import 'package:daalsetu/services/buyer_services.dart';
import 'package:get/get.dart';

import 'package:daalsetu/services/category_services.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';

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
    try {
      isLoading(true);
      isError(false);

      final data = await BuyerServices.getDashboard();
      
      // If the API nests it in a body key, we extract it.
      final actualData = data.containsKey('body') ? data['body'] : data;

      dashboardData.value = BuyerDashboardModel.fromJson(actualData);

      // Fetch Categories
      try {
        final cats = await CategoryService.fetchCategories();
        categories.assignAll(cats);
      } catch (e) {
        print("Failed to fetch categories: $e");
      }
    } catch (e) {
      isError(true);
      errorMessage(e.toString());
    } finally {
      isLoading(false);
    }
  }
}
