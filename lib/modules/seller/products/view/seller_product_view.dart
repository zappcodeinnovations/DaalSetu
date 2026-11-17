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
          onPressed: () => Navigator.of(context).maybePop(),
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

  Widget _buildProductCard(
    BuildContext context,
    SellerProductController controller,
    SellerProductModel product,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _statusPresentation(product);
    final cardRadius = BorderRadius.circular(20);

    return Material(
      color: theme.cardColor,
      borderRadius: cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('seller_product_card_${product.id}'),
        borderRadius: cardRadius,
        onTap: () => Get.to(
          () => ProductDetailScreen(productId: product.id),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFFFE0B2).withValues(alpha: 0.7),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFE65100).withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image / Media
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: primaryColor.withValues(alpha: 0.1),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: product.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              // Offer media previews need the JWT; a plain Image.network got 403.
                              child: AuthenticatedNetworkImage(
                                url: product.imageUrls.first,
                                fit: BoxFit.contain,
                                fallback: product.videoUrls.isNotEmpty
                                    ? const Icon(
                                        IconlyLight.video,
                                        color: primaryColor,
                                        size: 32,
                                      )
                                    : const Icon(
                                        IconlyLight.bag,
                                        color: primaryColor,
                                      ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                product.videoUrls.isNotEmpty
                                    ? IconlyLight.video
                                    : IconlyLight.bag,
                                color: primaryColor,
                                size: product.videoUrls.isNotEmpty ? 32 : 24,
                              ),
                            ),
                    ),
                    if (product.imageUrls.isNotEmpty &&
                        product.videoUrls.isNotEmpty)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Product Details & Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: status.color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
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
                    Text(
                      product.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _categoryBrandLabel(product),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "â‚¹${product.amount} / ${product.unit}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (product.loadingLocation.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyLight.location, size: 14, color: theme.disabledColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    product.loadingLocation,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _infoItem(IconlyLight.work, "${product.bagCount} Bags", theme),
              _infoItem(
                IconlyLight.info_square,
                "${product.packingWeight}kg",
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => const SellerOfferInterestsView(),
                    arguments: product.id,
                  ),
                  icon: const Icon(IconlyLight.chat, size: 14),
                  label: Text(
                    'Interests (${product.interestCount})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: const BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => SellerStockUpdateDialog.show(
                  context,
                  product.id,
                  onSuccess: controller.fetchProducts,
                ),
                icon: const Icon(IconlyLight.work, size: 14),
                label: const Text("Stock", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Get.to(
                  () => SellerMediaGalleryView(productId: product.id),
                  arguments: product.id,
                ),
                icon: const Icon(IconlyLight.image, size: 14),
                label: const Text("Media", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _infoItem(IconData icon, String text, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.transparent : const Color(0xFFFFECB3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFE65100)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? null : const Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
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
