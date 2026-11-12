import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../model/product_media_model.dart';
import '../../../../services/seller_services.dart';
import '../../../../services/product_services.dart';
import '../../../../network/api_client.dart';
import 'seller_product_controller.dart';
import '../../common/seller_ui.dart';

class SellerMediaController extends GetxController {
  final int productId;
  SellerMediaController({required this.productId});

  var isLoading = true.obs;
  var isUploading = false.obs;
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
      final List<ProductImageModel> combinedImages = [];
      final List<ProductVideoModel> combinedVideos = [];

      // 1. Authoritative offer detail from web endpoint (/api/offers/<id>/)
      if (productId > 0) {
        try {
          final offerRes = await SellerServices.getOfferDetail(productId);
          final offerData = offerRes['product'] is Map<String, dynamic>
              ? offerRes['product'] as Map<String, dynamic>
              : (offerRes['data'] is Map<String, dynamic>
                    ? offerRes['data'] as Map<String, dynamic>
                    : offerRes);

          final offerImagesRaw = offerData['images'];
          if (offerImagesRaw is List) {
            for (final item in offerImagesRaw) {
              if (item is Map) {
                combinedImages.add(
                  ProductImageModel.fromJson(
                    Map<String, dynamic>.from(item),
                    defaultProductId: productId,
                  ),
                );
              }
            }
          }

          final offerVideosRaw =
              offerData['product_videos'] ??
              offerData['videos'] ??
              offerData['video'];
          if (offerVideosRaw is List) {
            for (final item in offerVideosRaw) {
              if (item is Map) {
                combinedVideos.add(
                  ProductVideoModel.fromJson(
                    Map<String, dynamic>.from(item),
                    defaultProductId: productId,
                  ),
                );
              }
            }
          }
        } catch (_) {
          // Non-critical: continue to global media endpoints
        }
      }

      // 2. Fetch from dedicated product media endpoints
      try {
        final media = await Future.wait([
          SellerServices.getProductImages(
            productId: productId > 0 ? productId : null,
          ),
          SellerServices.getProductVideos(
            productId: productId > 0 ? productId : null,
          ),
        ]);

        final fetchedImages = media[0]
            .whereType<Map>()
            .map(
              (e) => ProductImageModel.fromJson(
                Map<String, dynamic>.from(e),
                defaultProductId: productId > 0 ? productId : null,
              ),
            )
            .where((img) => productId <= 0 || img.productId == productId)
            .toList();

        final fetchedVideos = media[1]
            .whereType<Map>()
            .map(
              (e) => ProductVideoModel.fromJson(
                Map<String, dynamic>.from(e),
                defaultProductId: productId > 0 ? productId : null,
              ),
            )
            .where((vid) => productId <= 0 || vid.productId == productId)
            .toList();

        for (final img in fetchedImages) {
          final exists = combinedImages.any(
            (x) =>
                (x.id != null && x.id == img.id) ||
                (x.imageUrl != null && x.imageUrl == img.imageUrl),
          );
          if (!exists) combinedImages.add(img);
        }

        for (final vid in fetchedVideos) {
          final exists = combinedVideos.any(
            (x) =>
                (x.id != null && x.id == vid.id) ||
                (x.videoUrl != null && x.videoUrl == vid.videoUrl),
          );
          if (!exists) combinedVideos.add(vid);
        }
      } catch (_) {
        // Non-critical
      }

      // 3. Fallback to product detail endpoint if still empty
      if (productId > 0 && (combinedImages.isEmpty || combinedVideos.isEmpty)) {
        try {
          final detail = await ProductService.getProductDetail(productId);
          if (combinedImages.isEmpty && detail.images.isNotEmpty) {
            combinedImages.addAll(
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
          if (combinedVideos.isEmpty && detail.videos.isNotEmpty) {
            combinedVideos.addAll(
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

      imagesList.assignAll(combinedImages);
      videosList.assignAll(combinedVideos);
    } catch (e) {
      _showNotification(
        "Could not load media",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        isError: true,
      );
    } finally {
      isLoading(false);
    }
  }

  void _showNotification(String title, String message, {bool isError = false}) {
    if (Get.context != null && !Get.testMode) {
      if (isError) {
        SellerUi.error(message);
      } else {
        SellerUi.success(message);
      }
    }
  }

  Future<void> uploadImage(String filePath, {bool isPrimary = true}) async {
    if (isUploading.value) return;

    final file = File(filePath);
    if (!file.existsSync()) {
      _showNotification(
        "Invalid file",
        "The selected image file could not be found.",
        isError: true,
      );
      return;
    }

    try {
      isUploading(true);
      if (Get.context != null) {
        Get.dialog(
          const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text("Uploading image..."),
                    ],
                  ),
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }
      await SellerServices.uploadProductImage(
        productId,
        filePath,
        isPrimary: isPrimary,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      _showNotification("Success", "Image uploaded successfully");
      await fetchMedia();
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showNotification(
        "Upload failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        isError: true,
      );
    } finally {
      isUploading(false);
    }
  }

  Future<void> deleteImage(int imageId) async {
    try {
      await SellerServices.deleteProductImage(imageId);
      _showNotification("Deleted", "Image removed");
      await fetchMedia();
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
    } catch (e) {
      _showNotification(
        "Delete failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> uploadVideo(
    String filePath,
    String title, {
    bool isPrimary = true,
  }) async {
    if (isUploading.value) return;

    final file = File(filePath);
    if (!file.existsSync()) {
      _showNotification(
        "Invalid file",
        "The selected video file could not be found.",
        isError: true,
      );
      return;
    }

    final fileSize = file.lengthSync();
    const maxSizeBytes = 100 * 1024 * 1024; // 100MB limit from backend
    if (fileSize > maxSizeBytes) {
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      _showNotification(
        "File too large",
        "Video size must be 100MB or less. Selected file is ${sizeMb}MB.",
        isError: true,
      );
      return;
    }

    final ext = filePath.split('.').last.toLowerCase();
    const allowed = ['mp4', 'mov', 'avi', 'webm'];
    if (!allowed.contains(ext)) {
      _showNotification(
        "Unsupported format",
        "Allowed video formats are MP4, MOV, AVI, and WEBM.",
        isError: true,
      );
      return;
    }

    try {
      isUploading(true);
      if (Get.context != null) {
        Get.dialog(
          PopScope(
            canPop: false,
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Uploading video...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Please wait while your video is uploaded.\nDo not close the application.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          barrierDismissible: false,
        );
      }
      await SellerServices.uploadProductVideo(
        productId,
        filePath,
        title,
        isPrimary: isPrimary,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      _showNotification("Success", "Video uploaded successfully");
      await fetchMedia();
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showNotification(
        "Upload failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        isError: true,
      );
    } finally {
      isUploading(false);
    }
  }

  Future<void> deleteVideo(int videoId) async {
    try {
      await SellerServices.deleteProductVideo(videoId);
      _showNotification("Deleted", "Video removed");
      await fetchMedia();
      if (Get.isRegistered<SellerProductController>()) {
        Get.find<SellerProductController>().fetchProducts(silent: true);
      }
    } catch (e) {
      _showNotification(
        "Delete failed",
        ApiClient.userFriendlyErrorMessage(e.toString()),
        isError: true,
      );
    }
  }
}
