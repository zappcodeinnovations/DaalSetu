import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/glass_widgets.dart';
import '../../../widgets/authenticated_network_image.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import '../controller/product_controller.dart';
import '../model/product_model.dart';
import './add_product.dart';
import './edit_product.dart';
import './product_detail.dart';

class ProductScreen extends StatelessWidget {
  ProductScreen({super.key});

  final ProductController controller = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AdminDrawer(activeKey: 'offers'),
      appBar: AppBar(
        title: Text(
          "Products",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Get.to(() => const AddProductScreen()),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text(
                  'Create Offer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                );
              }

              if (controller.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyLight.bag,
                        size: 48,
                        color: theme.iconTheme.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No offers available",
                        style: GoogleFonts.inter(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchProducts,
                color: theme.colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  itemCount: controller.products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                      context,
                      controller.products[index],
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final imageUrl = product.images.isNotEmpty
        ? product.images.first.imageUrl
        : null;
    final isAvailable = product.status.toLowerCase() == "available";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.to(() => ProductDetailScreen(productId: product.id)),
        child: GlassCard(
          padding: EdgeInsets.zero,
          glowColor: isAvailable ? AppTheme.successGreen : AppTheme.errorRed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: imageUrl != null
                        ? AuthenticatedNetworkImage(
                            url: imageUrl,
                            height: 180,
                            width: double.infinity,
                            fallback: _imageFallback(theme),
                          )
                        : _imageFallback(theme),
                  ),

                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isAvailable ? AppTheme.successGreen : AppTheme.errorRed)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isAvailable ? AppTheme.successGreen : AppTheme.errorRed)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        product.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category?.name ?? "No Category",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹ ${product.amount}",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location + Seller
                    Row(
                      children: [
                        Icon(
                          IconlyLight.location,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.loadingLocation,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          IconlyLight.profile,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.seller?.username ?? "-",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.dividerColor),
                    const SizedBox(height: 8),
                    Obx(() {
                      final processing =
                          controller.processingProductId.value == product.id;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: processing
                                  ? null
                                  : () => Get.to(
                                      () => EditProductScreen(product: product),
                                    ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: processing
                                  ? null
                                  : () => _confirmDelete(product),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              icon: processing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                processing ? 'Deleting...' : 'Delete',
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(ThemeData theme) {
    return Container(
      height: 180,
      width: double.infinity,
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(
        IconlyLight.image,
        size: 48,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '“${product.title}” will be permanently removed. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed == true) await controller.deleteProduct(product);
  }
}
