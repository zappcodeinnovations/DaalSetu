import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/product_media_model.dart';
import '../../../../services/seller_services.dart';

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
      final rawImages = await SellerServices.getProductImages(productId: productId);
      imagesList.value = rawImages.map((e) => ProductImageModel.fromJson(e)).toList();

      final rawVideos = await SellerServices.getProductVideos(productId: productId);
      videosList.value = rawVideos.map((e) => ProductVideoModel.fromJson(e)).toList();
    } catch (e) {
      Get.snackbar("Error", "Could not load media: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  Future<void> uploadImage(String filePath, {bool isPrimary = true}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.uploadProductImage(productId, filePath, isPrimary: isPrimary);
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Success", "Image uploaded successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchMedia();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteImage(int imageId) async {
    try {
      await SellerServices.deleteProductImage(imageId);
      Get.snackbar("Deleted", "Image removed", snackPosition: SnackPosition.BOTTOM);
      fetchMedia();
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> uploadVideo(String filePath, String title, {bool isPrimary = true}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await SellerServices.uploadProductVideo(productId, filePath, title, isPrimary: isPrimary);
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Success", "Video uploaded successfully", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      fetchMedia();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteVideo(int videoId) async {
    try {
      await SellerServices.deleteProductVideo(videoId);
      Get.snackbar("Deleted", "Video removed", snackPosition: SnackPosition.BOTTOM);
      fetchMedia();
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
