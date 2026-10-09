import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../../../../network/api_client.dart';
import '../model/seller_brand_model.dart';
import '../model/seller_tag_model.dart';
import '../../common/seller_ui.dart';

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
    isLoading.value = true;
    final results =
        await Future.wait<Object>([
          SellerServices.getBrandsList(),
          SellerServices.getCategoryTree(),
          SellerServices.getTagsList(),
        ]).catchError((Object error) {
          Get.snackbar(
            "Could not load master data",
            ApiClient.userFriendlyErrorMessage(error.toString()),
            snackPosition: SnackPosition.BOTTOM,
          );
          return <Object>[<dynamic>[], <dynamic>[], <dynamic>[]];
        });
    final brandsData = results[0] as List;
    final treeData = results[1] as List;
    final tagsData = results[2] as List;
    brandsList.assignAll(
      brandsData.whereType<Map>().map(
        (e) => SellerBrandModel.fromJson(Map<String, dynamic>.from(e)),
      ),
    );
    categoryTreeList.assignAll(treeData);
    tagsList.assignAll(
      tagsData.whereType<Map>().map(
        (e) => SellerTagModel.fromJson(Map<String, dynamic>.from(e)),
      ),
    );
    isLoading.value = false;
  }

  Future<void> createBrand(String name, {String? description}) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.createBrand(
        name,
        description: description,
      );
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "Success",
        res['message'] ?? "Brand created successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchAllMasters();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Error",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> editBrand(SellerBrandModel brand) async {
    if (brand.id == null) return;
    final controller = TextEditingController(text: brand.name ?? '');
    final name = await Get.dialog<String>(
      AlertDialog(
        title: const Text(
          "Edit Brand",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Brand name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == brand.name) return;
    final result = await SellerUi.run(
      () => SellerServices.updateBrand(brand.id!, name),
    );
    if (result != null) fetchAllMasters();
  }

  Future<void> deleteBrand(SellerBrandModel brand) async {
    if (brand.id == null) return;
    final ok = await SellerUi.confirm(
      "Delete Brand",
      "Delete brand \"${brand.name}\"?",
      confirmText: "Delete",
      color: Colors.red,
    );
    if (!ok) return;
    final result = await SellerUi.run(
      () => SellerServices.deleteBrand(brand.id!),
    );
    if (result != null) fetchAllMasters();
  }

  Future<void> editTag(SellerTagModel tag) async {
    if (tag.id == null) return;
    final controller = TextEditingController(text: tag.name ?? '');
    final name = await Get.dialog<String>(
      AlertDialog(
        title: const Text(
          "Edit Tag",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tag name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () => Get.back(result: controller.text.trim()),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == tag.name) return;
    final result = await SellerUi.run(
      () => SellerServices.updateTag(tag.id!, name),
    );
    if (result != null) fetchAllMasters();
  }

  /// Tags assigned to users are refused by the server (no force delete from the app).
  Future<void> deleteTag(SellerTagModel tag) async {
    if (tag.id == null) return;
    final ok = await SellerUi.confirm(
      "Delete Tag",
      "Delete tag \"${tag.name}\"?",
      confirmText: "Delete",
      color: Colors.red,
    );
    if (!ok) return;
    final result = await SellerUi.run(() => SellerServices.deleteTag(tag.id!));
    if (result != null) fetchAllMasters();
  }

  Future<void> createTag(String name) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final res = await SellerServices.createTag(name);
      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        "Success",
        res['message'] ?? "Tag created successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchAllMasters();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Error",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
