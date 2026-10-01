import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../model/seller_brand_model.dart';
import '../model/seller_tag_model.dart';

class SellerMasterController extends GetxController {
  var isLoading = false.obs;
  var brandsList = <SellerBrandModel>[].obs;
  var categoryTreeList = <dynamic>[].obs;
  var tagsList = <SellerTagModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllMasters();
  }

  Future<void> fetchAllMasters() async {
    try {
      isLoading.value = true;
      final brandsData = await SellerServices.getBrandsList();
      brandsList.value = brandsData.map((e) => SellerBrandModel.fromJson(e as Map<String, dynamic>)).toList();

      final treeData = await SellerServices.getCategoryTree();
      categoryTreeList.value = treeData;

      final tagsData = await SellerServices.getTagsList();
      tagsList.value = tagsData.map((e) => SellerTagModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createBrand(String name, {String? description}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.createBrand(name, description: description);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Brand created successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchAllMasters();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> createTag(String name) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.createTag(name);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar("Success", res['message'] ?? "Tag created successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchAllMasters();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
