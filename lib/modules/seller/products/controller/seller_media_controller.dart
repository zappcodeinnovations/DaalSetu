import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/product_media_model.dart';
import '../../../../services/seller_services.dart';
import '../../../../services/product_services.dart';
import '../../../../network/api_client.dart';
import 'seller_product_controller.dart';

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
        SellerServices.getProductImages(
          productId: productId > 0 ? productId : null,
        ),
        SellerServices.getProductVideos(
          productId: productId > 0 ? productId : null,
        ),
      ]);

      final allImages = media[0]
          .whereType<Map>()
          .map((e) => ProductImageModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final allVideos = media[1]
          .whereType<Map>()
          .map((e) => ProductVideoModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (productId > 0) {
        imagesList.assignAll(
          allImages.where((img) => img.productId == productId),
        );
        videosList.assignAll(
          allVideos.where((vid) => vid.productId == productId),
        );

        // Fallback: If global media endpoints returned no media explicitly tagged with this productId,
        // check the product detail endpoint to see if media is attached directly to the offer.
        if (imagesList.isEmpty || videosList.isEmpty) {
          try {
            final detail = await ProductService.getProductDetail(productId);
            if (imagesList.isEmpty && detail.images.isNotEmpty) {
              imagesList.assignAll(
                detail.images.map(
                  (img) => ProductImageModel(
                    id: img.id,
                    productId: productId,
                    productTitle: detail.title,
                    imageUrl: img.imageUrl,
                    downloadUrl: img.downloadUrl,
                    isPrimary: img.isPrimary,
                  ),
                ),
              );
            }
            if (videosList.isEmpty && detail.videos.isNotEmpty) {
              videosList.assignAll(
                detail.videos.map(
                  (vid) => ProductVideoModel(
                    id: vid.id,
                    productId: productId,
                    productTitle: detail.title,
                    videoUrl: vid.videoUrl,
                    downloadUrl: vid.downloadUrl,
                    title: vid.title,
                    isPrimary: vid.isPrimary,
                  ),
                ),
              );
            }
          } catch (_) {
            // Non-critical fallback
          }
        }
      } else {
        imagesList.assignAll(allImages);
        videosList.assignAll(allVideos);
      }
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
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
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
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
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
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
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
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
    } catch (e) {
      Get.snackbar(
        "Delete failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
