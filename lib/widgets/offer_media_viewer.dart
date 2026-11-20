import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/widgets/authenticated_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

/// Opening an offer's photo or video straight from its card.
///
/// * photos only  -> full-screen photo viewer (swipe, two-finger zoom)
/// * one video    -> full-screen video player with every control
/// * photos + video -> split screen showing both; tapping a half opens it full screen
///
/// Returns false when the offer has no media, so the caller can open the details page instead.
bool openOfferMedia({
  required List<String> imageUrls,
  required List<String> videoUrls,
  String title = 'Offer media',
  int initialImage = 0,
}) {
  final images = imageUrls.where((u) => u.trim().isNotEmpty).toList();
  final videos = videoUrls.where((u) => u.trim().isNotEmpty).toList();
  if (images.isEmpty && videos.isEmpty) return false;
  if (videos.isEmpty) {
    openOfferImagePage(images, initialIndex: initialImage, title: title);
  } else if (images.isEmpty && videos.length == 1) {
    openOfferVideoPage(videos.first, title: title);
  } else {
    Get.to<void>(() => OfferMediaSplitPage(title: title, imageUrls: images, videoUrls: videos));
  }
  return true;
}

/// For cards that know only the first photo: loads the product's photos and videos, then opens them.
/// A small spinner shows while loading. Returns false (nothing opened) when there is no media or it
/// cannot be loaded, so the caller can open the details page instead.
Future<bool> openOfferMediaForProduct(int productId, {String title = 'Offer media'}) async {
  Get.dialog<void>(
    const Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
    barrierColor: Colors.black38,
  );
  try {
    final product = await ProductService.getProductDetail(productId, silent: true);
    if (Get.isDialogOpen == true) Get.back<void>();
    return openOfferMedia(
      imageUrls: product.images.map((i) => i.imageUrl).toList(),
      videoUrls: product.videos.map((v) => v.videoUrl).toList(),
      title: title,
    );
  } catch (_) {
    if (Get.isDialogOpen == true) Get.back<void>();
    return false;
  }
}

/// A header that stays readable on black, whatever light / dark colours the app theme gives AppBar.
PreferredSizeWidget _blackHeader(String title, {List<Widget>? actions}) => AppBar(
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  iconTheme: const IconThemeData(color: Colors.white),
  actionsIconTheme: const IconThemeData(color: Colors.white),
  titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
  systemOverlayStyle: SystemUiOverlayStyle.light,
  // Always shown, always white: the page can be left from the top-left corner.
  leading: Builder(
    builder: (context) => IconButton(
      key: const Key('media-back-button'),
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      onPressed: () => goBackOrHome(context),
    ),
  ),
  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
  actions: actions,
);

/// Full-screen video page: all player controls, white title and back arrow on black.
void openOfferVideoPage(String url, {String title = 'Offer video'}) {
  Get.to<void>(
    () => OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        backgroundColor: Colors.black,
        // Sideways the video needs the whole height, so the header is hidden.
        appBar: orientation == Orientation.landscape ? null : _blackHeader(title),
        body: SafeArea(
          top: orientation == Orientation.landscape,
          child: AuthenticatedVideoPlayer(url: url, enableFullscreen: false, fullControls: true),
        ),
      ),
    ),
  );
}

/// Full-screen photo viewer: swipe between photos, two-finger zoom.
void openOfferImagePage(List<String> urls, {int initialIndex = 0, String title = 'Offer photos'}) {
  Get.to<void>(() => _OfferImagePage(urls: urls, initialIndex: initialIndex, title: title));
}

class _OfferImagePage extends StatefulWidget {
  const _OfferImagePage({required this.urls, required this.initialIndex, required this.title});

  final List<String> urls;
  final int initialIndex;
  final String title;

  @override
  State<_OfferImagePage> createState() => _OfferImagePageState();
}

class _OfferImagePageState extends State<_OfferImagePage> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex.clamp(0, widget.urls.length - 1));
  late int _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
  final Map<int, TransformationController> _zoom = {};
  bool _zoomed = false;

  TransformationController _controllerFor(int i) {
    return _zoom.putIfAbsent(i, () {
      final c = TransformationController();
      c.addListener(() {
        final zoomed = c.value.getMaxScaleOnAxis() > 1.01;
        if (i == _index && zoomed != _zoomed && mounted) setState(() => _zoomed = zoomed);
      });
      return c;
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    for (final c in _zoom.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _blackHeader(total > 1 ? '${widget.title}  ${_index + 1} / $total' : widget.title),
      body: SafeArea(
        child: PageView.builder(
          key: const Key('offer-image-pages'),
          controller: _pages,
          // While zoomed in, a one-finger drag pans the photo instead of changing it.
          physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
          itemCount: total,
          onPageChanged: (i) => setState(() {
            _index = i;
            _zoomed = false;
          }),
          itemBuilder: (context, i) => InteractiveViewer(
            key: Key('offer-image-zoom-$i'),
            transformationController: _controllerFor(i),
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: AuthenticatedNetworkImage(
                url: widget.urls[i],
                width: MediaQuery.sizeOf(context).width,
                height: MediaQuery.sizeOf(context).height,
                fit: BoxFit.contain,
                fallback: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 56, color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photos and videos side by side (top / bottom on a phone held upright, left / right when
/// sideways). Tap the photos or the video to open it full screen.
class OfferMediaSplitPage extends StatelessWidget {
  const OfferMediaSplitPage({
    super.key,
    required this.title,
    required this.imageUrls,
    required this.videoUrls,
  });

  final String title;
  final List<String> imageUrls;
  final List<String> videoUrls;

  @override
  Widget build(BuildContext context) {
    final hasImages = imageUrls.isNotEmpty;
    final hasVideos = videoUrls.isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _blackHeader(title),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final panels = <Widget>[
              if (hasImages)
                Expanded(
                  child: _PhotoPanel(
                    key: const Key('offer-media-photos'),
                    urls: imageUrls,
                    title: title,
                  ),
                ),
              if (hasImages && hasVideos) const SizedBox(width: 6, height: 6),
              if (hasVideos)
                Expanded(
                  child: _VideoPanel(
                    key: const Key('offer-media-video'),
                    urls: videoUrls,
                    title: title,
                  ),
                ),
            ];
            return Padding(
              padding: const EdgeInsets.all(6),
              child: orientation == Orientation.landscape ? Row(children: panels) : Column(children: panels),
            );
          },
        ),
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PhotoPanel extends StatefulWidget {
  const _PhotoPanel({super.key, required this.urls, required this.title});

  final List<String> urls;
  final String title;

  @override
  State<_PhotoPanel> createState() => _PhotoPanelState();
}

class _PhotoPanelState extends State<_PhotoPanel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xFF111111),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                key: Key('offer-media-photo-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => openOfferImagePage(widget.urls, initialIndex: i, title: widget.title),
                child: AuthenticatedNetworkImage(
                  url: widget.urls[i],
                  fit: BoxFit.contain,
                  fallback: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: IgnorePointer(
                child: _PanelLabel(
                  Icons.photo_library_outlined,
                  widget.urls.length > 1 ? 'Photos ${_index + 1} / ${widget.urls.length}' : 'Photo',
                ),
              ),
            ),
            const Positioned(
              right: 8,
              bottom: 8,
              child: IgnorePointer(child: _PanelLabel(Icons.open_in_full_rounded, 'Tap to open')),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPanel extends StatefulWidget {
  const _VideoPanel({super.key, required this.urls, required this.title});

  final List<String> urls;
  final String title;

  @override
  State<_VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<_VideoPanel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xFF111111),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                key: Key('offer-media-video-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => openOfferVideoPage(widget.urls[i], title: widget.title),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F2937), Color(0xFF0B0F19)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.play_arrow_rounded, size: 46, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: IgnorePointer(
                child: _PanelLabel(
                  Icons.videocam_outlined,
                  widget.urls.length > 1 ? 'Video ${_index + 1} / ${widget.urls.length}' : 'Video',
                ),
              ),
            ),
            const Positioned(
              right: 8,
              bottom: 8,
              child: IgnorePointer(child: _PanelLabel(Icons.play_circle_outline_rounded, 'Tap to play')),
            ),
          ],
        ),
      ),
    );
  }
}
