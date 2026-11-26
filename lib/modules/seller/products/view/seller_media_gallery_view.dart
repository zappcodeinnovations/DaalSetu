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
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/offer_image_picker.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

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
    final raw =
        widget.productId ?? Get.parameters['productId'] ?? Get.arguments;
    if (raw is int) {
      productId = raw;
    } else {
      productId = int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final tag = 'seller_media_$productId';
    controller = Get.isRegistered<SellerMediaController>(tag: tag)
        ? Get.find<SellerMediaController>(tag: tag)
        : Get.put(SellerMediaController(productId: productId), tag: tag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<SellerMediaController>(
      tag: 'seller_media_$productId',
    )) {
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
        title: Text(mediaType == 'Image' ? 'Image limit reached' : '$mediaType already uploaded'),
        content: Text(
          mediaType == 'Image'
              ? 'You can upload up to $maxOfferImages images per offer. Delete an image first to add another.'
              : 'Only one ${mediaType.toLowerCase()} is allowed per product. Delete the existing ${mediaType.toLowerCase()} first, then upload its replacement.',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(screenSize.width * 0.95, 600.0),
              maxHeight: screenSize.height * 0.85,
            ),
            // Close sits in its own header row above the photo (like the video preview), never on top of it.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Product Image',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        key: const Key('image-preview-close'),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
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
                ),
                const SizedBox(height: 12),
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
        appBar: HeroHeader(
          title: "Media Gallery",
          subtitle: "Product images & videos gallery",
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
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
                                // The tile is filled and bordered, so the delete badge sits inside its corner.
                                Positioned.fill(
                                  child: InkWell(
                                    onTap: () => _previewImage(
                                      context,
                                      _url(item.imageUrl),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: theme.dividerColor),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
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
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 2,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      key: Key('media-delete-image-${item.id}'),
                                      customBorder: const CircleBorder(),
                                      onTap: () => controller.deleteImage(item.id!),
                                      child: const Padding(
                                        padding: EdgeInsets.all(7),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
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
                    child: Obx(
                      () => Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: controller.isUploading.value
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                ),
                          color: controller.isUploading.value ? Colors.grey : null,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          heroTag: null,
                          elevation: 0,
                          highlightElevation: 0,
                          backgroundColor: Colors.transparent,
                          onPressed: controller.isUploading.value
                              ? null
                              : () async {
                                  final room = maxOfferImages - controller.imagesList.length;
                                  if (room <= 0) {
                                    _showLimitMessage(context, 'Image');
                                    return;
                                  }
                                  // Multi-select, up to 10 images per offer.
                                  final picked = await pickOfferImages(room: room);
                                  if (picked.isNotEmpty) {
                                    controller.uploadImages(picked);
                                  }
                                },
                          icon: controller.isUploading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo, color: Colors.white),
                          label: Text(
                            controller.isUploading.value
                                ? "Uploading..."
                                : "Upload Image",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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
                                title: Text(item.title ?? "Video"),
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
                    child: Obx(
                      () => Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: controller.isUploading.value
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                ),
                          color: controller.isUploading.value ? Colors.grey : null,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: FloatingActionButton.extended(
                          heroTag: null,
                          elevation: 0,
                          highlightElevation: 0,
                          backgroundColor: Colors.transparent,
                          onPressed: controller.isUploading.value
                              ? null
                              : () async {
                                  if (controller.videosList.isNotEmpty) {
                                    _showLimitMessage(context, 'Video');
                                    return;
                                  }
                                  final picked = await picker.pickVideo(
                                    source: ImageSource.gallery,
                                  );
                                  if (picked != null) {
                                    controller.uploadVideo(
                                      picked.path,
                                      "Product Video",
                                    );
                                  }
                                },
                          icon: controller.isUploading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.videocam, color: Colors.white),
                          label: Text(
                            controller.isUploading.value
                                ? "Uploading..."
                                : "Upload Video",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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
          Flexible(
            child: Container(
              width: calculatedWidth,
              height: calculatedHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              // Two-finger (pinch) zoom, like the offer images.
              child: InteractiveViewer(
                key: const Key('video-preview-pinch-zoom'),
                minScale: 1,
                maxScale: 5,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: videoSize.width > 0 ? videoSize.width : 16,
                    height: videoSize.height > 0 ? videoSize.height : 9,
                    child: VideoPlayer(controller),
                  ),
                ),
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
            Flexible(child: content),
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
