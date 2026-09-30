import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/widgets/authenticated_network_image.dart';
import 'package:daalsetu/widgets/authenticated_video_player.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductModel> _product;

  @override
  void initState() {
    super.initState();
    _product = ProductService.getProductDetail(widget.productId);
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
                if (!product.isExpired && product.stockStatus.toLowerCase() != 'out_of_stock' && product.interestCount > 0)
                  _actionButtons(product, context),
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
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AuthenticatedNetworkImage(
                url: product.images[index].imageUrl,
                width: double.infinity,
                height: 240,
                fallback: const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          );
        },
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

  Widget _actionButtons(ProductModel product, BuildContext context) {
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
          onPressed: () {
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
          },
          icon: const Icon(Icons.handshake, color: Colors.white),
          label: const Text(
            'Manage Deal (Accept / Reject)',
            style: TextStyle(
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
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
