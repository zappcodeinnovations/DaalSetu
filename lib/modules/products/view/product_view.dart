import 'package:iconly/iconly.dart';
import './add_product.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/glass_widgets.dart';
import '../controller/product_controller.dart';
import '../model/product_model.dart';

class ProductScreen extends StatelessWidget {
  ProductScreen({super.key});

  final ProductController controller = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Products",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.secondary,
              theme.colorScheme.secondary.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.to(() => AddProductScreen()),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(IconlyLight.plus, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
      body: Obx(() {
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
                Icon(IconlyLight.bag, size: 48, color: theme.iconTheme.color),
                const SizedBox(height: 12),
                Text(
                  "No products available",
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: controller.products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(context, controller.products[index]);
            },
          ),
        );
      }),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imageUrl =
        product.images.isNotEmpty ? product.images.first.imageUrl : null;
    final isAvailable = product.status.toLowerCase() == "available";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        glowColor: isAvailable ? Colors.green : Colors.red,
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
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08),
                          child: Icon(
                            IconlyLight.image,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
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
                      color: (isAvailable ? Colors.green : Colors.red)
                          .withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isAvailable ? Colors.green : Colors.red)
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
