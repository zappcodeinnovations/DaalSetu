import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_product_controller.dart';
import '../model/seller_product_model.dart';
import 'add_product_view.dart';
import 'seller_stock_update_dialog.dart';
import 'seller_offer_interests_view.dart';
import 'seller_media_gallery_view.dart';
import 'edit_offer_view.dart';
import 'offer_stock_history_view.dart';
import '../../../../routes/app_routes.dart';

class SellerProductView extends StatelessWidget {
  const SellerProductView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerProductController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Products",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.sellerNotifications),
            icon: Icon(IconlyLight.notification, color: theme.iconTheme.color),
          ),
          IconButton(
            tooltip: 'Export offers',
            onPressed: controller.exportProducts,
            icon: Icon(IconlyLight.download, color: theme.iconTheme.color),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: controller.products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = controller.products[index];
              return _buildProductCard(context, controller, product);
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Get.to(() => const AddProductView()),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: primaryColor.withOpacity(0.1),
                ),
                child: product.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(IconlyLight.bag, color: primaryColor),
                        ),
                      )
                    : const Icon(IconlyLight.bag, color: primaryColor),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${product.amount} / ${product.unit}",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
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
          const Divider(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (product.loadingLocation.isNotEmpty)
                _infoItem(IconlyLight.location, product.loadingLocation, theme),
              _infoItem(IconlyLight.work, "${product.bagCount} Bags", theme),
              _infoItem(
                IconlyLight.info_square,
                "${product.packingWeight}kg",
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  () => const SellerMediaGalleryView(),
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
    );
  }

  Widget _infoItem(IconData icon, String text, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.disabledColor),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodySmall),
      ],
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
    if (!product.isActive || normalized == 'inactive') {
      return const _ProductStatusPresentation('INACTIVE', Colors.blueGrey);
    }
    return _ProductStatusPresentation(
      normalized.isEmpty ? 'STATUS UNKNOWN' : normalized.toUpperCase(),
      Colors.orange,
    );
  }
}

class _ProductStatusPresentation {
  const _ProductStatusPresentation(this.label, this.color);

  final String label;
  final Color color;
}
