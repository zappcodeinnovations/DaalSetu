import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconly/iconly.dart';
import 'package:video_player/video_player.dart';
import '../controller/seller_media_controller.dart';
import '../../../../comman/api_url.dart';
import '../../../../widgets/authenticated_network_image.dart';
import '../../../../widgets/media_url.dart';
import '../../../../utils/app_preferences.dart';

class SellerMediaGalleryView extends StatefulWidget {
  final int? productId;
  const SellerMediaGalleryView({super.key, this.productId});

  @override
  State<SellerMediaGalleryView> createState() => _SellerMediaGalleryViewState();
}

class _SellerMediaGalleryViewState extends State<SellerMediaGalleryView> {
  late final int productId;
  late final SellerMediaController controller;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final raw = widget.productId ??
        Get.parameters['productId'] ??
        Get.arguments;
    if (raw is int) {
      productId = raw;
    } else {
      productId = int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    controller = Get.put(
      SellerMediaController(productId: productId),
      tag: 'seller_media_$productId',
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<SellerMediaController>(tag: 'seller_media_$productId')) {
      Get.delete<SellerMediaController>(tag: 'seller_media_$productId');
    }
    super.dispose();
  }

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
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(screenSize.width * 0.95, 600.0),
              maxHeight: screenSize.height * 0.85,
            ),
            child: Stack(
              children: [
                InteractiveViewer(
                  maxScale: 4.0,
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
                  right: 6,
                  top: 6,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _previewVideo(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => DynamicVideoPreviewDialog(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

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

class DynamicVideoPreviewDialog extends StatefulWidget {
  final String url;
  const DynamicVideoPreviewDialog({super.key, required this.url});

  @override
  State<DynamicVideoPreviewDialog> createState() =>
      _DynamicVideoPreviewDialogState();
}

class _DynamicVideoPreviewDialogState extends State<DynamicVideoPreviewDialog> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final token = await AppPreferences.getAccessToken();
      final controller = VideoPlayerController.networkUrl(
        resolveMediaUri(widget.url),
        httpHeaders: token == null || token.isEmpty
            ? const {}
            : {'Authorization': 'Bearer $token'},
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final maxDialogWidth = math.min(screenSize.width * 0.92, 520.0);
    final maxDialogHeight = screenSize.height * 0.85;

    Widget content;
    double? dialogWidth;

    if (_error != null) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('Video could not be loaded')),
      );
    } else if (!_initialized || _controller == null) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFB300)),
        ),
      );
    } else {
      final controller = _controller!;
      final videoSize = controller.value.size;
      double aspectRatio = controller.value.aspectRatio;
      if (aspectRatio <= 0 || aspectRatio.isNaN) {
        aspectRatio = (videoSize.width > 0 && videoSize.height > 0)
            ? videoSize.width / videoSize.height
            : 16 / 9;
      }

      // Overhead space for title header, progress bar, play button, and close action:
      const overheadHeight = 148.0;
      final maxVideoHeight = math.max(120.0, maxDialogHeight - overheadHeight);
      final maxVideoWidth = math.max(120.0, maxDialogWidth - 32.0);

      // Dynamically calculate the video box dimensions preserving aspect ratio:
      double calculatedWidth = maxVideoWidth;
      double calculatedHeight = calculatedWidth / aspectRatio;
      if (calculatedHeight > maxVideoHeight) {
        calculatedHeight = maxVideoHeight;
        calculatedWidth = calculatedHeight * aspectRatio;
      }

      dialogWidth = calculatedWidth + 32.0;

      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: calculatedWidth,
            height: calculatedHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: videoSize.width > 0 ? videoSize.width : 16,
                height: videoSize.height > 0 ? videoSize.height : 9,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          const SizedBox(height: 8),
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.black12,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          const SizedBox(height: 4),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.white,
            ),
            tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            icon: Icon(
              controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: dialogWidth,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Product Video',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  splashRadius: 18,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFB300),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
