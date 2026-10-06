import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../buyer/offers/controller/buyer_offers_controller.dart';
import '../../../buyer/offers/model/buyer_offer_model.dart';
import '../../../../theme/app_theme.dart';

class TransporterOffersView extends StatelessWidget {
  const TransporterOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            "Pulse Offers",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: "All Offers"),
              Tab(text: "Today"),
              Tab(text: "Pending"),
              Tab(text: "Previous"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TransporterOfferList(offerType: 'all'),
            _TransporterOfferList(offerType: 'today'),
            _TransporterOfferList(offerType: 'pending'),
            _TransporterOfferList(offerType: 'previous'),
          ],
        ),
      ),
    );
  }
}

class _TransporterOfferList extends StatelessWidget {
  final String offerType;

  const _TransporterOfferList({required this.offerType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      BuyerOffersController(offerType: offerType),
      tag: offerType,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final offers = controller.offersList;

      if (isLoading && offers.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (offers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconlyLight.ticket_star, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 14),
              Text(
                "No offers found",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "There are no $offerType trade offers at the moment.",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchOffers,
        color: primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final offer = offers[index];
            final title = offer.displayTitle ?? offer.title ?? "Offer #${offer.id ?? ''}";
            final price = offer.displayPrice ?? (offer.requestedAmount != null ? "₹${offer.requestedAmount}" : "₹0");
            final quantity = offer.displayQuantity ?? "${offer.requestedQuantity ?? ''} ${offer.quantityUnit ?? ''}".trim();
            final status = offer.displayStatus ?? (offer.status ?? 'ACTIVE').toUpperCase();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        price,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (quantity.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quantity,
                            style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
