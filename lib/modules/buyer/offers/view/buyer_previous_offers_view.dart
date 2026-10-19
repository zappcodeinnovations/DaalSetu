import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../products/view/product_detail.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import 'buyer_offer_details_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class BuyerPreviousOffersView extends StatelessWidget {
  const BuyerPreviousOffersView({super.key});

  void _openDetails(BuyerOfferModel offer) {
    if (offer.isRfq && offer.id != null) {
      Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
    } else {
      final pId = offer.productId ?? offer.id;
      if (pId != null) {
        Get.to(() => ProductDetailScreen(productId: pId));
      } else if (offer.id != null) {
        Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BuyerOffersController(offerType: 'previous'), tag: 'previous');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Previous Offers",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isError.value) {
          return Center(
            child: Text(
              controller.errorMessage.value.replaceAll("Exception: ", ""),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        final offers = controller.offersList;

        if (offers.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.fetchOffers(),
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Text(
                    "No previous offers.",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchOffers(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final num? availNum = num.tryParse(
                (offer.availableQuantity ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
              );
              final num? bagsNum = num.tryParse(
                (offer.bagCount ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
              );
              final num? packingNum = num.tryParse(
                (offer.packingWeight ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
              );

              String displayQty;
              if (availNum != null && availNum > 0) {
                displayQty = "${availNum.toStringAsFixed(3)} ${offer.quantityUnit ?? 'QTL'}";
              } else if (bagsNum != null && bagsNum > 0 && packingNum != null && packingNum > 0) {
                final calcQtl = (bagsNum * packingNum) / 100.0;
                displayQty = "${calcQtl.toStringAsFixed(3)} QTL";
              } else if (offer.displayQuantity != null &&
                  offer.displayQuantity!.isNotEmpty &&
                  offer.displayQuantity != 'N/A' &&
                  !offer.displayQuantity!.startsWith('0.000') &&
                  !offer.displayQuantity!.startsWith('0 QTL')) {
                displayQty = offer.displayQuantity!;
              } else if (offer.requestedQuantity?.isNotEmpty == true &&
                  (num.tryParse(offer.requestedQuantity!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0) > 0) {
                displayQty = "${offer.requestedQuantity} ${offer.quantityUnit ?? 'QTL'}";
              } else if (bagsNum != null && bagsNum > 0) {
                displayQty = "$bagsNum Bags";
              } else {
                displayQty = offer.displayQuantity ?? "0.000 QTL";
              }

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openDetails(offer),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              offer.displayTitle ?? 'Offer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              offer.displayStatus ?? 'PREVIOUS',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (offer.code != null && offer.code!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          offer.code!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Available Quantity", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    displayQty,
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: theme.dividerColor.withValues(alpha: 0.4)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Offer Price", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    offer.displayPrice?.isNotEmpty == true ? offer.displayPrice! : 'Open',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (offer.brand != null || offer.category != null || offer.bagCount != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (offer.brand != null && offer.brand!.isNotEmpty)
                              _buildChip(theme, Icons.branding_watermark_outlined, offer.brand!),
                            if (offer.category != null && offer.category!.isNotEmpty && offer.category != offer.title)
                              _buildChip(theme, Icons.grain, offer.category!),
                            if (offer.bagCount != null && offer.bagCount!.isNotEmpty)
                              _buildChip(theme, IconlyLight.work, "${offer.bagCount} Bags"),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
