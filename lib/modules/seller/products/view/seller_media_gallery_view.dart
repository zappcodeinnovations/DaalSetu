import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_media_controller.dart';

class SellerMediaGalleryView extends StatelessWidget {
  const SellerMediaGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    final productIdStr = Get.parameters['productId'] ?? (Get.arguments?.toString() ?? '0');
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
          title: Text("Product Media Gallery", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          return TabBarView(
            children: [
              // Images Tab
              Stack(
                children: [
                  controller.imagesList.isEmpty
                      ? const Center(child: Text("No product images uploaded yet"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: controller.imagesList.length,
                          itemBuilder: (context, index) {
                            final item = controller.imagesList[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrl ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(IconlyLight.image, size: 40),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => controller.deleteImage(item.id!),
                                  ),
                                ),
                                if (item.isPrimary == true)
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("PRIMARY", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      backgroundColor: primaryColor,
                      onPressed: () async {
                        final picked = await picker.pickImage(source: ImageSource.gallery);
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
                      ? const Center(child: Text("No product videos uploaded yet"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: controller.videosList.length,
                          itemBuilder: (context, index) {
                            final item = controller.videosList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(IconlyLight.video, color: primaryColor),
                                title: Text(item.title ?? "Video #${item.id}"),
                                subtitle: Text(item.videoUrl ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => controller.deleteVideo(item.id!),
                                ),
                              ),
                            );
                          },
                        ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      backgroundColor: primaryColor,
                      onPressed: () async {
                        final picked = await picker.pickVideo(source: ImageSource.gallery);
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
