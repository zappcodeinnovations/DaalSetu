import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/widgets/authenticated_video_player.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductModel> _product;
  String _role = '';

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
    _product = ProductService.getProductDetail(widget.productId);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = (await AppPreferences.getRole() ?? '').trim().toLowerCase();
    if (mounted) setState(() => _role = role);
  }

  Future<void> _refresh() async {
    setState(() {
      _product = ProductService.getProductDetail(widget.productId);
    });
    await _product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: FutureBuilder<ProductModel>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            );
          }
          final product = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                _images(product),
                const SizedBox(height: 14),
                _header(product),
                if (_canManageInterests)
                  _buildDealActionButton(product, context),
                _section('Offer information', [
                  _item('Product ID', product.id),
                  _item('Title', product.title),
                  _item('Description', product.description),
                  _item('Category', product.category?.name),
                  _item('Root category', product.rootCategory?.name),
                  _item('Brand', product.brand?.name),
                  _item('Brand ID', product.brand?.uniqueId),
                  _item('Seller', product.seller?.fullName),
                  _item('Seller login', product.seller?.loginUsername),
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
                  _item('Remaining bags', product.remainingBagCount),
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
                if (product.videos.isNotEmpty) ...[
                  Text(
                    'Product videos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...product.videos.map(
                    (video) => Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AuthenticatedVideoPlayer(url: video.videoUrl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
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
        itemBuilder: (context, index) {
          final imageUrl = product.images[index].imageUrl;
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
        },
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
