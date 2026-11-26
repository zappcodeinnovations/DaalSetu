import 'package:video_player/video_player.dart';
import 'package:daalsetu/widgets/media_url.dart';
import 'package:daalsetu/widgets/offer_media_viewer.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class ProductDetailScreen extends StatefulWidget {
  /// Buyer screens pass this to show "Submit Offer" on the offer page (MoM 7);
  /// it opens the same Submit Offer dialog as the offers list.
  final void Function(BuildContext context)? onSubmitOffer;

  /// True when this buyer already sent an offer on it: the button then says "Resubmit", like the offer card.
  /// Read inside an Obx, so it flips as soon as the offer goes through.
  final bool Function()? isOfferSubmitted;
  final bool isResubmit;
  final ProductModel? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.onSubmitOffer,
    this.isOfferSubmitted,
    this.isResubmit = false,
    this.initialProduct,
  });
  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductModel> _product;
  String _role = '';
  final RxInt _dummyRx = 0.obs;

  bool get _canManageInterests => const {
    'seller',
    'both_sellerandbuyer',
    'admin',
    'super_admin',
    'sub_admin',
  }.contains(_role);

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct != null
        ? Future.value(widget.initialProduct!)
        : ProductService.getProductDetail(widget.productId, silent: true);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = (await AppPreferences.getRole() ?? '').trim().toLowerCase();
    if (mounted) setState(() => _role = role);
  }

  Future<void> _refresh() async {
    setState(() {
      _product = ProductService.getProductDetail(widget.productId, silent: true);
    });
    try {
      await _product;
    } catch (_) {
      // FutureBuilder displays the request error inline, including on retry.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeroHeader(
        title: 'Product Details',
        subtitle: 'Commodity specifications & seller terms',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: _refresh,
        ),
      ),
      body: FutureBuilder<ProductModel>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            final error = snapshot.error;
            final unavailable = error is ApiRequestException && error.statusCode == 404;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(unavailable ? Icons.inventory_2_outlined : Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      unavailable ? 'Product unavailable' : 'Could not load product',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unavailable
                          ? 'This product may have been removed or is not available to your current account or panel.'
                          : 'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (unavailable && Navigator.canPop(context))
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go back'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: Text(unavailable ? 'Check again' : 'Retry'),
                      ),
                  ],
                ),
              ),
            );
          }
          final product = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                _mediaBar(product),
                const SizedBox(height: 14),
                _header(product),
                if (product.isExpired)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF8B4B4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF9B1C1C), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Deal has expired. You cannot show interest.",
                            style: TextStyle(
                              color: Color(0xFF9B1C1C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.onSubmitOffer != null)
                  _buildSubmitOfferButton(product, context)
                else if (_canManageInterests)
                  _buildDealActionButton(product, context),
                _section('Offer information', [
                  _item('Title', product.title),
                  _item('Description', product.description),
                  _item('Category', product.category?.name),
                  _item('Root category', product.rootCategory?.name),
                  _item('Brand', product.brand?.name),
                  _item('Brand ID', product.brand?.uniqueId),
                  _item('Seller', product.seller?.fullName),
                  // The web has no seller login field (switched off, kept commented out).
                  // _item('Seller login', product.seller?.loginUsername),
                ]),
                _section('Pricing & inventory', [
                  _item('Rate', '₹${product.amount} ${product.amountUnit}'),
                  _item(
                    'Original quantity',
                    '${product.originalQuantity} ${product.quantityUnit}',
                  ),
                  _item(
                    'Remaining quantity',
                    '${product.remainingQuantity} ${product.quantityUnit}',
                  ),
                  _item('Available quantity', product.availableQuantity),
                  _item('Quantity (Qtl)', product.quantityQtl),
                  _item('Packing weight', '${product.packingWeightKg} kg'),
                  _item('Original bags', product.originalBagCount),
                  // The web only shows the remaining quantity (what is left after sales), not remaining bags.
                  // _item('Remaining bags', product.remainingBagCount),
                  _item('Stock status', _label(product.stockStatus)),
                ]),
                _section('Loading & expiry', [
                  _item('Loading from', _date(product.loadingFrom)),
                  _item('Loading to', _date(product.loadingTo)),
                  _item('Loading location', product.loadingLocation),
                  _item('Deal expiry', _date(product.dealExpiryDatetime)),
                  _item('Expired', product.isExpired ? 'Yes' : 'No'),
                ]),
                _section('Status & activity', [
                  _item('Status', _label(product.status)),
                  _item('Deal status', _label(product.dealStatus)),
                  _item('Active', product.isActive ? 'Yes' : 'No'),
                  _item('Interest count', product.interestCount),
                  _item('Remark', product.remark),
                  _item('Created', _date(product.createdAt)),
                  _item('Updated', _date(product.updatedAt)),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Top media bar (MoM 6): offer images and videos in one slider; a video
  /// slide opens the full-screen player (with two-finger zoom) when tapped.
  Widget _mediaBar(ProductModel product) {
    final total = product.images.length + product.videos.length;
    if (product.videos.isEmpty) return _images(product);
    return SizedBox(
      height: 240,
      child: PageView.builder(
        key: const Key('product-media-bar'),
        itemCount: total,
        itemBuilder: (context, index) {
          final Widget slide = index < product.images.length
              ? _imageSlide(product.images[index].imageUrl)
              : OfferVideoSlide(
                  posterUrl: product.images.isNotEmpty ? product.images.first.imageUrl : null,
                  video: product.videos[index - product.images.length],
                  onTap: () => _openVideo(product.videos[index - product.images.length]),
                );
          return Stack(
            fit: StackFit.expand,
            children: [
              slide,
              if (total > 1)
                Positioned(
                  left: 12,
                  top: 10,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: Text(
                          '${index + 1} / $total',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openVideo(ProductVideo video) {
    // Full-screen player with every control and a white title / back arrow on black.
    openOfferVideoPage(video.videoUrl, title: video.title.trim().isEmpty ? 'Offer video' : video.title);
  }

  Widget _images(ProductModel product) {
    if (product.images.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.image_not_supported_outlined, size: 56),
      );
    }
    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: product.images.length,
        itemBuilder: (context, index) => _imageSlide(product.images[index].imageUrl),
      ),
    );
  }

  Widget _imageSlide(String imageUrl) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showImagePreview(imageUrl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      child: AuthenticatedNetworkImage(
                        url: imageUrl,
                        width: double.infinity,
                        height: 240,
                        fit: BoxFit.contain,
                        fallback: const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.zoom_out_map_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  void _showImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: AuthenticatedNetworkImage(
                      url: imageUrl,
                      width: MediaQuery.sizeOf(dialogContext).width,
                      height: MediaQuery.sizeOf(dialogContext).height,
                      fit: BoxFit.contain,
                      fallback: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 56,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filled(
                  tooltip: 'Close image',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.65),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(product.category?.name ?? 'No category'),
                ],
              ),
            ),
            Text(
              '₹${product.amount}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Buyer's "Submit Offer" right on the seller's offer page.
  Widget _buildSubmitOfferButton(ProductModel product, BuildContext context) {
    final unavailable = product.isExpired ||
        product.stockStatus.toLowerCase() == 'out_of_stock' ||
        !product.isActive;
    // Expired / out of stock already shows its own notice: no dead button.
    if (unavailable) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          key: const Key('product-submit-offer'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            widget.onSubmitOffer!(context);
          },
          icon: const Icon(Icons.send_rounded, color: Colors.white),
          label: widget.isOfferSubmitted != null
              ? Obx(() {
                  _dummyRx.value;
                  final isSubmitted =
                      (widget.isOfferSubmitted?.call() ?? false) || widget.isResubmit;
                  return Text(
                    isSubmitted ? 'Resubmit' : 'Submit Offer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  );
                })
              : Text(
                  widget.isResubmit ? 'Resubmit' : 'Submit Offer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildDealActionButton(ProductModel product, BuildContext context) {
    final isOutOfStock =
        product.stockStatus.toLowerCase() == 'out_of_stock' ||
        product.isExpired;
    final hasInterests = product.interestCount > 0;

    // 1. Out of stock with 0 interests: Hide button completely (Clean UI)
    if (isOutOfStock && !hasInterests) {
      return const SizedBox.shrink();
    }

    void openDialog() {
      showDialog(
        context: context,
        builder: (ctx) => OfferInterestsDialog(
          offerId: product.id.toString(),
          offerTitle: product.title,
          availableStock: product.availableQuantity,
          sellerOfferAmount: product.amount.toString(),
          dealExpiry: product.dealExpiryDatetime,
        ),
      );
    }

    // 2. Out of stock but has past interests: Secondary "View Deal History"
    if (isOutOfStock) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: openDialog,
            icon: const Icon(Icons.history),
            label: Text(
              'View Deal History (${product.interestCount})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      );
    }

    // 3. In stock: Full active "Manage Deal (Accept / Reject)"
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: openDialog,
          icon: const Icon(Icons.handshake, color: Colors.white),
          label: Text(
            hasInterests
                ? 'Manage Deal (${product.interestCount})'
                : 'Manage Deal (Accept / Reject)',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    ),
  );

  Widget _item(String name, Object? rawValue) {
    final value = rawValue?.toString().trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(name, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String value) => value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  String _date(String value) {
    if (value.trim().isEmpty || value == '-') return '—';
    final trimmed = value.trim();

    final isoMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})',
    ).firstMatch(trimmed);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!) ?? 0;
      final m = int.tryParse(isoMatch.group(2)!) ?? 1;
      final d = int.tryParse(isoMatch.group(3)!) ?? 1;
      final h = int.tryParse(isoMatch.group(4)!) ?? 0;
      final min = int.tryParse(isoMatch.group(5)!) ?? 0;

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final monthName = (m >= 1 && m <= 12) ? months[m - 1] : '$m';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      final minuteStr = min.toString().padLeft(2, '0');
      final amPm = h >= 12 ? 'PM' : 'AM';
      return '$d $monthName $y, $hour12:$minuteStr $amPm';
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return DateFormat('d MMM yyyy, hh:mm a').format(local);
  }
}

/// A video in the offer's top media bar (MoM 6): a frame of the video as its poster, a play
/// button and the title; tap opens it. While the frame loads (or when it cannot), the offer's first
/// photo is shown instead, and a dark gradient only as the last fallback.
class OfferVideoSlide extends StatefulWidget {
  const OfferVideoSlide({super.key, required this.video, required this.onTap, this.posterUrl});

  final ProductVideo video;
  final VoidCallback onTap;
  final String? posterUrl;

  @override
  State<OfferVideoSlide> createState() => _OfferVideoSlideState();
}

class _OfferVideoSlideState extends State<OfferVideoSlide> {
  VideoPlayerController? _frame;
  bool _frameReady = false;

  bool get _hasPhoto => (widget.posterUrl ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // With a photo of the offer the poster is that photo (always shows); the video's own frame is only read
    // when there is no photo, because on many phones a paused video paints a black frame.
    if (!_hasPhoto) _loadFrame();
  }

  /// Opens the video muted and paused just after the start, so its first picture is the poster.
  Future<void> _loadFrame() async {
    try {
      final token = await AppPreferences.getAccessToken();
      final hasToken = token != null && token.isNotEmpty;
      final uri = resolveMediaUri(widget.video.videoUrl);
      final controller = VideoPlayerController.networkUrl(
        hasToken ? uri.replace(queryParameters: {...uri.queryParameters, 'token': token}) : uri,
        httpHeaders: hasToken ? {'Authorization': 'Bearer $token'} : const {},
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _frame = controller;
      await controller.initialize();
      await controller.setVolume(0);
      // Past the usual black first frames, then play a moment and pause: Android only paints the picture of a
      // video that has started playing once.
      final duration = controller.value.duration;
      final target = duration > const Duration(seconds: 2) ? const Duration(seconds: 1) : const Duration(milliseconds: 300);
      await controller.seekTo(target);
      await controller.play();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await controller.pause();
      if (mounted) setState(() => _frameReady = true);
    } catch (_) {
      // No frame (offline, unsupported format ...): the photo / gradient poster stays.
    }
  }

  @override
  void dispose() {
    _frame?.dispose();
    super.dispose();
  }

  Widget _poster() {
    final frame = _frame;
    if (!_hasPhoto && _frameReady && frame != null && frame.value.isInitialized) {
      return FittedBox(
        key: const Key('offer-video-poster-frame'),
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: frame.value.size.width,
          height: frame.value.size.height,
          child: VideoPlayer(frame),
        ),
      );
    }
    final photo = widget.posterUrl;
    if (_hasPhoto && photo != null) {
      return AuthenticatedNetworkImage(
        key: const Key('offer-video-poster-photo'),
        url: photo,
        fit: BoxFit.cover,
        fallback: const _PosterGradient(),
      );
    }
    return const _PosterGradient();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.black,
          child: InkWell(
            key: Key('product-video-slide-${video.videoUrl.hashCode}'),
            onTap: widget.onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _poster()),
                // Darken the bottom so the title stays readable on any picture.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22000000), Color(0x99000000)],
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 42),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    children: [
                      const Icon(Icons.videocam_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          video.title.trim().isEmpty ? 'Offer video' : video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Text('Tap to play', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterGradient extends StatelessWidget {
  const _PosterGradient();

  @override
  Widget build(BuildContext context) {
    // A branded poster (never a plain black box) when neither a photo nor a video frame is available.
    return const DecoratedBox(
      key: Key('offer-video-poster-gradient'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment(0, -0.45),
        child: Icon(Icons.movie_outlined, color: Colors.white38, size: 54),
      ),
    );
  }
}
