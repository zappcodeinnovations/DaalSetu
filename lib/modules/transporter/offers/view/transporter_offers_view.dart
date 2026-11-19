import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../buyer/offers/controller/buyer_offers_controller.dart';
import '../../../../theme/app_theme.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class TransporterOffersView extends StatelessWidget {
  const TransporterOffersView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: HeroHeader(
          title: "Pulse Offers",
          subtitle: "Active commodity trade offers",
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => goBackOrHome(context),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: "Offers"),
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
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => Get.find<BuyerOffersController>(tag: offerType).fetchOffers(silent: true),
    tabIndex: const ['all', 'today', 'pending', 'previous'].indexOf(offerType),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
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
        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
      }

      if (offers.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.fetchOffers,
          color: primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(IconlyLight.ticket_star, size: 56, color: Color(0xFFFF9800)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No offers found",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offerType == 'all'
                          ? "There are no trade offers at the moment."
                          : "There are no $offerType trade offers at the moment.",
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchOffers,
        color: primary,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final offer = offers[index];
            final title = offer.displayTitle ?? offer.title ?? "Offer";
            final price = offer.displayPrice ?? (offer.requestedAmount != null ? "₹${offer.requestedAmount}" : "₹0");
            final quantity = offer.displayQuantity ?? "${offer.requestedQuantity ?? ''} ${offer.quantityUnit ?? ''}".trim();
            final status = offer.displayStatus ?? (offer.status ?? 'ACTIVE').toUpperCase();

            // Status chip color styling
            Color statusColor;
            Color statusBg;
            Color statusBorder;
            switch (status.toLowerCase()) {
              case 'active':
              case 'open':
                statusColor = const Color(0xFF2E7D32);
                statusBg = const Color(0xFFE8F5E9);
                statusBorder = const Color(0xFF81C784);
                break;
              case 'pending':
                statusColor = const Color(0xFFE65100);
                statusBg = const Color(0xFFFFF3E0);
                statusBorder = const Color(0xFFFFB74D);
                break;
              case 'completed':
              case 'accepted':
                statusColor = Colors.blue.shade700;
                statusBg = Colors.blue.shade50;
                statusBorder = Colors.blue.shade200;
                break;
              default:
                statusColor = Colors.grey.shade700;
                statusBg = Colors.grey.shade100;
                statusBorder = Colors.grey.shade300;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (quantity.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            quantity,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE65100),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusBorder, width: 0.8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
