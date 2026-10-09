import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/product_media_model.dart';
import '../../../../services/seller_services.dart';
import '../../../../network/api_client.dart';

class SellerMediaController extends GetxController {
  final int productId;
  SellerMediaController({required this.productId});

  var isLoading = true.obs;
  var imagesList = <ProductImageModel>[].obs;
  var videosList = <ProductVideoModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMedia();
  }

  Future<void> fetchMedia() async {
    try {
      isLoading(true);
      final media = await Future.wait([
        SellerServices.getProductImages(productId: productId),
        SellerServices.getProductVideos(productId: productId),
      ]);
      imagesList.assignAll(
        media[0].whereType<Map>().map(
          (e) => ProductImageModel.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
      videosList.assignAll(
        media[1].whereType<Map>().map(
          (e) => ProductVideoModel.fromJson(Map<String, dynamic>.from(e)),
        ),
      );
    } catch (e) {
      Get.snackbar(
        "Could not load media",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> uploadImage(String filePath, {bool isPrimary = true}) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await SellerServices.uploadProductImage(
        productId,
        filePath,
        isPrimary: isPrimary,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Success",
        "Image uploaded successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchMedia();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Upload failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteImage(int imageId) async {
    try {
      await SellerServices.deleteProductImage(imageId);
      Get.snackbar(
        "Deleted",
        "Image removed",
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchMedia();
    } catch (e) {
      Get.snackbar(
        "Delete failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> uploadVideo(
    String filePath,
    String title, {
    bool isPrimary = true,
  }) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await SellerServices.uploadProductVideo(
        productId,
        filePath,
        title,
        isPrimary: isPrimary,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Success",
        "Video uploaded successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await fetchMedia();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        "Upload failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deleteVideo(int videoId) async {
    try {
      await SellerServices.deleteProductVideo(videoId);
      Get.snackbar(
        "Deleted",
        "Video removed",
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchMedia();
    } catch (e) {
      Get.snackbar(
        "Delete failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
