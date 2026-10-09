import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_media_controller.dart';
import '../../../../comman/api_url.dart';
import '../../../../widgets/authenticated_network_image.dart';
import '../../../../widgets/authenticated_video_player.dart';

class SellerMediaGalleryView extends StatelessWidget {
  const SellerMediaGalleryView({super.key});

  String _url(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty ||
        raw.startsWith('http://') ||
        raw.startsWith('https://')) {
      return raw;
    }
    return '${ApiUrls.baseUrl}${raw.startsWith('/') ? '' : '/'}$raw';
  }

  void _showLimitMessage(BuildContext context, String mediaType) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$mediaType already uploaded'),
        content: Text(
          'Only one ${mediaType.toLowerCase()} is allowed per product. Delete the existing ${mediaType.toLowerCase()} first, then upload its replacement.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _previewImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: AuthenticatedNetworkImage(
                url: url,
                fit: BoxFit.contain,
                fallback: const SizedBox(
                  height: 260,
                  child: Center(child: Text('Image could not be loaded')),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previewVideo(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Product Video'),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: 520,
          child: AuthenticatedVideoPlayer(url: url),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productIdStr =
        Get.parameters['productId'] ?? (Get.arguments?.toString() ?? '0');
    final productId = int.tryParse(productIdStr) ?? 0;

    final controller = Get.put(
      SellerMediaController(productId: productId),
      tag: 'seller_media_$productId',
    );

    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);
    final picker = ImagePicker();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Product Media Gallery",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            tabs: [
              Tab(icon: Icon(IconlyLight.image), text: "Images"),
              Tab(icon: Icon(IconlyLight.video), text: "Videos"),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          return TabBarView(
            children: [
              // Images Tab
              Stack(
                children: [
                  controller.imagesList.isEmpty
                      ? const Center(
                          child: Text("No product images uploaded yet"),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: controller.imagesList.length,
                          itemBuilder: (context, index) {
                            final item = controller.imagesList[index];
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: InkWell(
                                    onTap: () => _previewImage(
                                      context,
                                      _url(item.imageUrl),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AuthenticatedNetworkImage(
                                        url: _url(item.imageUrl),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fallback: Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            IconlyLight.image,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        controller.deleteImage(item.id!),
                                  ),
                                ),
                                if (item.isPrimary == true)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "PRIMARY",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: null,
                      backgroundColor: primaryColor,
                      onPressed: () async {
                        if (controller.imagesList.isNotEmpty) {
                          _showLimitMessage(context, 'Image');
                          return;
                        }
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          controller.uploadImage(picked.path);
                        }
                      },
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text("Upload Image"),
                    ),
                  ),
                ],
              ),
              // Videos Tab
              Stack(
                children: [
                  controller.videosList.isEmpty
                      ? const Center(
                          child: Text("No product videos uploaded yet"),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.videosList.length,
                          itemBuilder: (context, index) {
                            final item = controller.videosList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(
                                  IconlyLight.video,
                                  color: primaryColor,
                                ),
                                title: Text(item.title ?? "Video #${item.id}"),
                                subtitle: const Text('Tap to play'),
                                onTap: () =>
                                    _previewVideo(context, _url(item.videoUrl)),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      controller.deleteVideo(item.id!),
                                ),
                              ),
                            );
                          },
                        ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: null,
                      backgroundColor: primaryColor,
                      onPressed: () async {
                        if (controller.videosList.isNotEmpty) {
                          _showLimitMessage(context, 'Video');
                          return;
                        }
                        final picked = await picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          controller.uploadVideo(picked.path, "Product Video");
                        }
                      },
                      icon: const Icon(Icons.videocam),
                      label: const Text("Upload Video"),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
