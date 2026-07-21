import 'package:agro_broker/services/category_services.dart';
import 'package:get/get.dart';
import '../model/category_model.dart';

class CategoryController extends GetxController {

  var isLoading = false.obs;
  var categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    fetchCategories();
    super.onInit();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final data = await CategoryService.fetchCategories();
      categories.assignAll(data);

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
