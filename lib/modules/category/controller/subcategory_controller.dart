import '../model/subcategory_model.dart';
import '../../../services/category_services.dart';
import 'package:get/get.dart';

class SubCategoryController extends GetxController {
  var isLoading = false.obs;
  var subcategories = <SubCategoryModel>[].obs;

  var categoryId = 0;
  var categoryName = "".obs;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args != null) {
      categoryId = args["categoryId"] ?? 0;
      categoryName.value = args["categoryName"] ?? "";
    }

    fetchSubCategories();
  }

  Future<void> fetchSubCategories() async {
    try {
      isLoading.value = true;

      final data = await CategoryService.fetchSubCategories();

      // Filter locally
      subcategories.value =
          data.where((e) => e.category?.id == categoryId).toList();

    } catch (e) {
      
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
