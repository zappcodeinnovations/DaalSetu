import 'package:daalsetu/widgets/offer_media_viewer.dart';
import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_product_controller.dart';
import '../model/seller_product_model.dart';
import '../../../products/view/product_detail.dart';
import 'add_product_view.dart';
import 'seller_stock_update_dialog.dart';
import 'seller_offer_interests_view.dart';
import 'seller_media_gallery_view.dart';
import 'edit_offer_view.dart';
import 'offer_stock_history_view.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/authenticated_network_image.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/offer_card_parts.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class SellerProductView extends StatelessWidget {
  const SellerProductView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => Get.find<SellerProductController>().fetchProducts(silent: true),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
    final controller = Get.put(SellerProductController());
    final theme = Theme.of(context);
    // An extendBody navigation shell includes its bar height in body padding.
    // Reserve that space only when this screen is embedded in that shell.
    final navigationInset =
        Scaffold.maybeOf(context)?.widget.bottomNavigationBar != null
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "My Products",
        subtitle: "Active listings & stock inventory",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Get.toNamed(AppRoutes.sellerNotifications),
              icon: const Icon(IconlyLight.notification, color: Colors.white, size: 22),
            ),
            IconButton(
              tooltip: 'Share offers',
              onPressed: controller.shareProducts,
              icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
            ),
            IconButton(
              tooltip: 'Download offers',
              onPressed: controller.exportProducts,
              icon: const Icon(IconlyLight.download, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchProducts,
        color: primaryColor,
        child: Obx(() {
          if (controller.isLoading.value && controller.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (controller.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.bag, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    "No products listed yet",
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + navigationInset),
            itemCount: controller.products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = controller.products[index];
              return _buildProductCard(context, controller, product);
            },
          );
        }),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navigationInset),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE65100),
                Color(0xFFF57C00),
                Color(0xFFFFA000),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE65100).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            key: const Key('seller-add-product-button'),
            heroTag: null,
            onPressed: () => Get.to(() => const AddProductView()),
            backgroundColor: Colors.transparent,
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: const Text(
              "Add Product",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Same card layout as the buyer's Offers screen: thumbnail, title, heart count and status,
  /// a quantity | price box, metadata chips, then the seller's actions.
  Widget _buildProductCard(
    BuildContext context,
    SellerProductController controller,
    SellerProductModel product,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _statusPresentation(product);
    final cardRadius = BorderRadius.circular(18);
    final categoryBrand = _categoryBrandLabel(product);
    final created = '${product.createdAt.day.toString().padLeft(2, '0')} '
        '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][product.createdAt.month - 1]} '
        '${product.createdAt.year}';

    return InkWell(
      key: Key('seller_product_card_${product.id}'),
      borderRadius: cardRadius,
      onTap: () => Get.to(
        () => ProductDetailScreen(productId: product.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: offerCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo / video thumbnail (a play badge marks a photo that also has a video).
                // Tap = open the photo / video right away (both: split screen).
                GestureDetector(
                  key: Key('seller_product_media_${product.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final opened = openOfferMedia(
                      imageUrls: product.imageUrls,
                      videoUrls: product.videoUrls,
                      title: product.title,
                    );
                    if (!opened) Get.to(() => ProductDetailScreen(productId: product.id));
                  },
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: product.imageUrls.isNotEmpty
                              // Offer media previews need the JWT; a plain Image.network got 403.
                              ? AuthenticatedNetworkImage(
                                  url: product.imageUrls.first,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  fallback: product.videoUrls.isNotEmpty
                                      ? const Center(
                                          child: Icon(IconlyLight.video, color: primaryColor, size: 26),
                                        )
                                      : const OfferNoMedia(),
                                )
                              : (product.videoUrls.isNotEmpty
                                    ? const Center(
                                        child: Icon(IconlyLight.video, color: primaryColor, size: 26),
                                      )
                                    : const OfferNoMedia()),
                        ),
                        if (product.imageUrls.isNotEmpty && product.videoUrls.isNotEmpty)
                          Positioned(
                            right: 3,
                            bottom: 3,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OfferHeartBadge(count: '${product.interestCount}'),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
                            icon: Icon(Icons.more_vert, size: 20, color: theme.iconTheme.color),
                            onSelected: (value) async {
                              switch (value) {
                                case 'edit':
                                  final updated = await Get.to(
                                    () => EditOfferView(productId: product.id),
                                  );
                                  if (updated == true) controller.fetchProducts();
                                  break;
                                case 'toggle':
                                  controller.toggleOffer(product);
                                  break;
                                case 'history':
                                  Get.to(
                                    () => OfferStockHistoryView(
                                      productId: product.id,
                                      title: product.title,
                                    ),
                                  );
                                  break;
                                case 'delete':
                                  controller.deleteOffer(product);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text("Edit Offer")),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(product.isActive ? "Deactivate" : "Activate"),
                              ),
                              const PopupMenuItem(
                                value: 'history',
                                child: Text("Stock History"),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text("Delete", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          OfferStatusBadge(label: status.label, color: status.color),
                          if (categoryBrand.isNotEmpty)
                            Text(
                              categoryBrand,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OfferHighlights(
              qtyLabel: 'Available Quantity',
              qtyValue: _quantityLabel(product),
              priceLabel: 'Offer Price',
              priceValue: "₹${product.amount} / ${product.unit}",
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OfferInfoChip(icon: IconlyLight.work, text: "${product.bagCount} Bags"),
                OfferInfoChip(icon: Icons.scale_outlined, text: "${product.packingWeight}kg"),
                if (product.loadingLocation.isNotEmpty)
                  OfferInfoChip(icon: IconlyLight.location, text: product.loadingLocation),
                OfferInfoChip(icon: IconlyLight.time_circle, text: created),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.to(
                  () => ProductDetailScreen(productId: product.id),
                ),
                icon: const Icon(IconlyLight.show, size: 16),
                label: const Text(
                  'View Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.to(
                      () => const SellerOfferInterestsView(),
                      arguments: product.id,
                    ),
                    icon: const Icon(IconlyLight.chat, size: 14),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Interests (${product.interestCount})',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                  onPressed: () => SellerStockUpdateDialog.show(
                    context,
                    product.id,
                    onSuccess: controller.fetchProducts,
                  ),
                  icon: const Icon(IconlyLight.work, size: 14),
                  label: const Text("Stock", maxLines: 1, style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => SellerMediaGalleryView(productId: product.id),
                    arguments: product.id,
                  ),
                  icon: const Icon(IconlyLight.image, size: 14),
                  label: const Text("Media", maxLines: 1, style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Stock left, e.g. "16.700 QTL"; falls back to bags x packing when the server sends none.
  String _quantityLabel(SellerProductModel product) {
    final unit = product.quantityUnit.trim().isEmpty ? 'qtl' : product.quantityUnit.trim();
    final stock = double.tryParse(product.quantity.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (stock != null && stock > 0) return '${stock.toStringAsFixed(3)} ${unit.toUpperCase()}';
    if (product.bagCount > 0 && product.packingWeight > 0) {
      return '${(product.bagCount * product.packingWeight / 100).toStringAsFixed(3)} QTL';
    }
    return '0.000 ${unit.toUpperCase()}';
  }

  String _categoryBrandLabel(SellerProductModel product) {
    final labels = <String>[
      if ((product.categoryName ?? '').trim().isNotEmpty)
        product.categoryName!.trim(),
      if ((product.brandName ?? '').trim().isNotEmpty)
        product.brandName!.trim(),
    ];
    return labels.isEmpty ? 'Category not specified' : labels.join(' | ');
  }

  _ProductStatusPresentation _statusPresentation(SellerProductModel product) {
    if (!product.isActive) {
      return const _ProductStatusPresentation('INACTIVE', Colors.blueGrey);
    }
    final normalized = product.status.trim().toLowerCase();
    if (product.isExpired || normalized.contains('expired')) {
      return const _ProductStatusPresentation(
        'DEAL EXPIRED',
        Colors.deepOrange,
      );
    }
    if (normalized == 'out_of_stock' || normalized == 'out of stock') {
      return const _ProductStatusPresentation('OUT OF STOCK', Colors.red);
    }
    if (normalized == 'active' || normalized == 'available') {
      return const _ProductStatusPresentation('AVAILABLE', Colors.green);
    }
    if (normalized == 'sold') {
      return const _ProductStatusPresentation('SOLD', Colors.redAccent);
    }
    if (normalized == 'sold_pending_confirmation' || normalized.contains('pending')) {
      return const _ProductStatusPresentation('PENDING CONFIRMATION', Colors.orange);
    }
    if (normalized == 'inactive') {
      return const _ProductStatusPresentation('INACTIVE', Colors.blueGrey);
    }
    return _ProductStatusPresentation(
      normalized.isEmpty ? 'STATUS UNKNOWN' : normalized.replaceAll('_', ' ').toUpperCase(),
      Colors.orange,
    );
  }
}

class _ProductStatusPresentation {
  const _ProductStatusPresentation(this.label, this.color);

  final String label;
  final Color color;
}
