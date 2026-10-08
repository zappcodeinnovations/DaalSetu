import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../products/view/product_detail.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import 'buyer_offer_details_view.dart';

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
      appBar: AppBar(
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
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openDetails(offer),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
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
                                fontSize: 16,
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
                              offer.displayStatus ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Quantity: ${offer.displayQuantity}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            offer.displayPrice ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
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
}
