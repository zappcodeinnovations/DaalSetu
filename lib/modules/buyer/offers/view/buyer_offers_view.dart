import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../widgets/authenticated_network_image.dart';
import '../../../../widgets/delivery_period_picker.dart';
import '../../../products/view/product_detail.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import 'add_buyer_offer_view.dart';
import 'buyer_offer_details_view.dart';
import 'buyer_negotiation_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/widgets/hero_header.dart';

/// Opens the buyer's Submit Offer dialog for a seller offer. Used by the offer
/// detail page (MoM 7) from every buyer screen that opens it.
void showBuyerSubmitOfferDialog(BuildContext context, BuyerOfferModel offer, {String tag = 'all'}) {
  final pId = offer.productId ?? offer.id;
  if (pId == null) return;
  final controller = Get.isRegistered<BuyerOffersController>(tag: tag)
      ? Get.find<BuyerOffersController>(tag: tag)
      : Get.put(BuyerOffersController(offerType: tag), tag: tag);
  _OfferList(offerType: tag)._showInterestDialog(context, controller, pId, offer);
}

/// The detail-page callback, or null when this offer cannot take a new offer.
void Function(BuildContext)? buyerSubmitOfferCallback(BuyerOfferModel offer, {String tag = 'all'}) {
  if (!offer.canSubmitOffer || offer.isExpired || offer.isOutOfStock || !offer.isActive) return null;
  return (context) => showBuyerSubmitOfferDialog(context, offer, tag: tag);
}

class BuyerOffersView extends StatelessWidget {
  final int initialIndex;
  const BuyerOffersView({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      initialIndex: (initialIndex >= 0 && initialIndex < 4) ? initialIndex : 0,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: HeroHeader(
          leading: AppBarLeading(
            child: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(
                      IconlyLight.arrow_left_2,
                      color: Colors.white,
                    ),
                    onPressed: () => Get.back(),
                  )
                : null,
          ),
          title: "Offers",
          bottom: TabBar(
            isScrollable: false,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: "Offers"),
              Tab(text: "Today"),
              Tab(text: "Pending"),
              Tab(text: "Previous"),
            ],
          ),
        ),
        // "Post Requirement" lives only on the Activity tab.
        body: const TabBarView(
          children: [
            _OfferList(offerType: 'all'),
            _OfferList(offerType: 'today'),
            _OfferList(offerType: 'pending'),
            _OfferList(offerType: 'previous'),
          ],
        ),
      ),
    );
  }
}

class _OfferList extends StatelessWidget {
  final String offerType;

  const _OfferList({required this.offerType});

  void _openDetails(BuyerOfferModel offer, String type) {
    if ((type == 'requirements' || offer.isRfq) && offer.id != null) {
      Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
    } else {
      final pId = offer.productId ?? offer.id;
      if (pId != null) {
        Get.to(() => ProductDetailScreen(
              productId: pId,
              onSubmitOffer: buyerSubmitOfferCallback(offer, tag: offerType),
            ));
      } else if (offer.id != null) {
        Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => Get.find<BuyerOffersController>(tag: offerType).fetchOffers(silent: true),
    tabIndex: const ['all', 'today', 'pending', 'previous'].indexOf(offerType),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = Get.put(
      BuyerOffersController(offerType: offerType),
      tag: offerType,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              onChanged: controller.searchOffers,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: offerType == 'requirements'
                    ? "Search requirements..."
                    : "Search offers (name, price, qty)...",
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  IconlyLight.search,
                  size: 20,
                  color: Color(0xFFF57C00),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.allOffersList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.isError.value && controller.allOffersList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 60,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Unable to Load Offers",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.errorMessage.value.isNotEmpty
                            ? controller.errorMessage.value
                            : "Something went wrong while loading offers.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => controller.fetchOffers(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final offers = controller.offersList;

            if (offers.isEmpty) {
              final isSearching = controller.searchQuery.value.isNotEmpty;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 60,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSearching ? "No Matching Offers" : "No Offers Found",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSearching
                            ? "No offers match '${controller.searchQuery.value}'"
                            : (offerType == 'requirements'
                                  ? "You haven't posted any requirements yet."
                                  : (offerType == 'all'
                                      ? "No offers are available at the moment."
                                      : "No $offerType offers are available at the moment.")),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (offerType == 'requirements' && !isSearching)
                        ElevatedButton.icon(
                          onPressed: () =>
                              Get.to(() => const AddBuyerOfferScreen()),
                          icon: const Icon(IconlyLight.plus),
                          label: const Text("Post New Requirement"),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => controller.fetchOffers(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("Refresh"),
                        ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchOffers(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 200),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  final offer = offers[index];
                  final isReq = offerType == 'requirements' || offer.isRfq;
                  final isInterestsTab = offerType == 'interests';
                  final qtyLabel = isInterestsTab
                      ? "Required Qty"
                      : (isReq ? "Required Quantity" : "Available Quantity");
                  final priceLabel = isInterestsTab
                      ? "Offered Amount"
                      : (isReq ? "Target Price" : "Offer Price");

                  final num? availNum = num.tryParse(
                    (offer.availableQuantity ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
                  );
                  final num? bagsNum = num.tryParse(
                    (offer.bagCount ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
                  );
                  final num? packingNum = num.tryParse(
                    (offer.packingWeight ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
                  );

                  String displayQtyStr;
                  if (availNum != null && availNum > 0) {
                    displayQtyStr = "${availNum.toStringAsFixed(3)} ${offer.quantityUnit ?? 'QTL'}";
                  } else if (bagsNum != null && bagsNum > 0 && packingNum != null && packingNum > 0) {
                    final calcQtl = (bagsNum * packingNum) / 100.0;
                    displayQtyStr = "${calcQtl.toStringAsFixed(3)} QTL";
                  } else if (offer.displayQuantity != null &&
                      offer.displayQuantity!.isNotEmpty &&
                      offer.displayQuantity != 'N/A' &&
                      !offer.displayQuantity!.startsWith('0.000') &&
                      !offer.displayQuantity!.startsWith('0 QTL')) {
                    displayQtyStr = offer.displayQuantity!;
                  } else if (offer.requestedQuantity?.isNotEmpty == true &&
                      (num.tryParse(offer.requestedQuantity!.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0) > 0) {
                    displayQtyStr = "${offer.requestedQuantity} ${offer.quantityUnit ?? 'QTL'}";
                  } else if (bagsNum != null && bagsNum > 0) {
                    displayQtyStr = "$bagsNum Bags";
                  } else {
                    displayQtyStr = offer.displayQuantity ?? "0.000 QTL";
                  }

                  final displayPriceStr = isInterestsTab
                      ? (offer.requestedAmount?.isNotEmpty == true
                            ? "₹${offer.requestedAmount}"
                            : (offer.displayPrice?.isNotEmpty == true
                                  ? offer.displayPrice!
                                  : 'Open'))
                      : (offer.displayPrice?.isNotEmpty == true
                            ? offer.displayPrice!
                            : (offer.requestedAmount?.isNotEmpty == true
                                  ? "₹${offer.requestedAmount}/${(offer.amountUnit ?? offer.quantityUnit ?? 'QTL').toUpperCase()}"
                                  : 'Open'));

                  final displayBagsStr = offer.bagCount != null && offer.bagCount!.isNotEmpty
                      ? "${offer.bagCount} Bags"
                      : null;
                  final displayPackingStr = offer.packingWeight != null && offer.packingWeight!.isNotEmpty
                      ? "${offer.packingWeight} KG"
                      : null;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openDetails(offer, offerType),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isDark ? theme.cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header: Thumbnail + Title/Heart & Status/Code/Brand
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image thumbnail / NO MEDIA box
                              ClipRRect(
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
                                  child: (offer.imageUrl != null &&
                                          offer.imageUrl!.isNotEmpty)
                                      ? AuthenticatedNetworkImage(
                                          url: offer.imageUrl!,
                                          width: 58,
                                          height: 58,
                                          fit: BoxFit.cover,
                                          fallback:
                                              _buildNoMediaPlaceholder(theme),
                                        )
                                      : _buildNoMediaPlaceholder(theme),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Title + Heart & Status/Code/Brand
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Title + Heart badge
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            offer.displayTitle ?? 'Offer',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildHeartBadge(
                                          offer.interestCount ?? '0',
                                          isDark,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Row 2: Status & Code & Brand in a responsive Wrap
                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _buildStatusBadge(
                                          offer.displayStatus ?? 'ACTIVE',
                                          theme,
                                        ),
                                        if (offer.code != null &&
                                            offer.code!.isNotEmpty)
                                          Text(
                                            offer.code!,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFEA580C),
                                            ),
                                          ),
                                        if (offer.brand != null &&
                                            offer.brand!.isNotEmpty &&
                                            offer.brand != offer.displayTitle)
                                          Text(
                                            offer.brand!,
                                            style: GoogleFonts.inter(
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

                          // Main Highlights Box: Available/Required Quantity & Offer/Target Price / Offered Amount
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1A2235) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2D3B55) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.15) : const Color(0xFFFFF7ED),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          IconlyLight.buy,
                                          size: 16,
                                          color: Color(0xFFEA580C),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              qtyLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              displayQtyStr,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: isDark ? const Color(0xFF2D3B55) : const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF059669).withValues(alpha: 0.15) : const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          IconlyLight.wallet,
                                          size: 16,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              priceLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              displayPriceStr,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Metadata Chips: Variety, Bags/Packing, Interest Date, Pickup, Location
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (offer.category != null &&
                                  offer.category!.isNotEmpty &&
                                  offer.category != offer.title)
                                _buildBadge(
                                  theme,
                                  Icons.grain,
                                  offer.category!,
                                ),
                              if (displayBagsStr != null)
                                _buildBadge(
                                  theme,
                                  IconlyLight.work,
                                  displayBagsStr,
                                ),
                              if (displayPackingStr != null)
                                _buildBadge(
                                  theme,
                                  Icons.scale_outlined,
                                  "Packing: $displayPackingStr",
                                ),
                              if (offer.createdAt != null &&
                                  offer.createdAt!.isNotEmpty)
                                _buildBadge(
                                  theme,
                                  IconlyLight.time_circle,
                                  isInterestsTab
                                      ? "Interest Date: ${offer.createdAt!}"
                                      : offer.createdAt!,
                                ),
                              if (offer.pickupFrom != null &&
                                  offer.pickupFrom!.isNotEmpty)
                                _buildBadge(
                                  theme,
                                  IconlyLight.calendar,
                                  "Pickup: ${offer.pickupFrom}${(offer.pickupTo != null && offer.pickupTo!.isNotEmpty) ? ' - ${offer.pickupTo}' : ''}",
                                ),
                              if (offer.location != null &&
                                  offer.location!.isNotEmpty)
                                _buildBadge(
                                  theme,
                                  IconlyLight.location,
                                  offer.location!,
                                ),
                              if (offer.sellerName != null &&
                                  offer.sellerName!.isNotEmpty)
                                _buildBadge(
                                  theme,
                                  Icons.storefront_outlined,
                                  offer.sellerName!,
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          _buildActionButtons(
                            context,
                            controller,
                            offer,
                            offerType,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNoMediaPlaceholder(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF2C394F), Color(0xFF202B3D)]
              : const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.grain_rounded,
              size: 24,
              color: Color(0xFFEA580C),
            ),
            const SizedBox(height: 2),
            Text(
              "DAAL",
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartBadge(String count, [bool isDark = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFE11D48).withValues(alpha: 0.15) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFFE11D48).withValues(alpha: 0.35) : const Color(0xFFFECDD3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 11, color: Color(0xFFE11D48)),
          const SizedBox(width: 3.5),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final sUpper = status.toUpperCase().replaceAll('_', ' ');
    final isOutOfStock = sUpper.contains('OUT OF STOCK') || sUpper.contains('SOLD OUT');
    final isGood = !isOutOfStock &&
        (sUpper.contains('ACTIVE') ||
            sUpper.contains('AVAILABLE') ||
            sUpper.contains('OPEN') ||
            sUpper.contains('CONFIRM') ||
            sUpper.contains('DEAL CONFIRMED'));
    final isBad = isOutOfStock ||
        sUpper.contains('EXPIRED') ||
        sUpper.contains('REJECT') ||
        sUpper.contains('CANCEL') ||
        sUpper.contains('CLOSED') ||
        sUpper.contains('INACTIVE') ||
        sUpper.contains('DISABLED') ||
        (sUpper.contains('SOLD') && !sUpper.contains('PARTIAL'));
    final isWarning = !isOutOfStock &&
        (sUpper.contains('PARTIAL') ||
            sUpper.contains('PARTIALLY SOLD') ||
            sUpper.contains('NEGOTIAT') ||
            sUpper.contains('PENDING') ||
            sUpper.contains('INTEREST'));

    final Color bgColor = isGood
        ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFDCFCE7))
        : (isBad
            ? (isDark ? const Color(0xFFDC2626).withValues(alpha: 0.2) : const Color(0xFFFEE2E2))
            : (isWarning
                ? (isDark ? const Color(0xFFD97706).withValues(alpha: 0.2) : const Color(0xFFFEF3C7))
                : (isDark ? const Color(0xFFEA580C).withValues(alpha: 0.2) : const Color(0xFFFFEDD5))));

    final Color textColor = isGood
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isBad
            ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
            : (isWarning
                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                : (isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C))));

    final Color borderColor = isGood
        ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFF86EFAC))
        : (isBad
            ? (isDark ? const Color(0xFFDC2626).withValues(alpha: 0.4) : const Color(0xFFFCA5A5))
            : (isWarning
                ? (isDark ? const Color(0xFFD97706).withValues(alpha: 0.4) : const Color(0xFFFCD34D))
                : (isDark ? const Color(0xFFEA580C).withValues(alpha: 0.4) : const Color(0xFFFDBA74))));

    String displayStatus = status;
    if (sUpper.contains('EXPIRED')) {
      displayStatus = 'Deal Expired';
    } else if (isOutOfStock) {
      displayStatus = 'OUT OF STOCK';
    } else if (status.trim().toUpperCase() == 'AVAILABLE') {
      displayStatus = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, IconData icon, String text) {
    if (text.trim().isEmpty || (text.startsWith('{') && text.endsWith('}'))) {
      return const SizedBox.shrink();
    }
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFEA580C)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    BuyerOffersController controller,
    BuyerOfferModel offer,
    String type,
  ) {
    if (type == 'interests') {
      final productId = offer.productId ?? offer.id ?? 0;
      final isConfirmed = offer.isConfirmed;
      final isRejected = offer.isRejected;
      final isActionable = !isConfirmed && !isRejected;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          _ActionBtn(
            label: "View",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
          if (isActionable)
            _ActionBtn(
              label: "Edit",
              color: Theme.of(context).colorScheme.primary,
              icon: IconlyLight.edit,
              onTap: () =>
                  _showInterestDialog(context, controller, productId, offer),
            ),
          if (offer.canOpenNegotiation && !isConfirmed)
            _ActionBtn(
              label: "Negotiation",
              color: const Color(0xFFE65100),
              icon: Icons.chat_outlined,
              onTap: () => Get.to(() => BuyerNegotiationView(offer: offer)),
            ),
        ],
      );
    }

    if (type == 'requirements' || offer.isRfq) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ActionBtn(
            label: "View Details",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
        ],
      );
    }

    final productId = offer.productId ?? offer.id;
    if (productId == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ActionBtn(
            label: "View",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
        ],
      );
    }

    // For active/today/all offers without interest:
    if (type == 'today' || type == 'all') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          _ActionBtn(
            label: "View",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
          // Expired / out of stock is already shown in the status badge; no second copy here.
          if (offer.isExpired || offer.isOutOfStock)
            ...const <Widget>[]
          else if (!offer.isActive)
            _ActionBtn(
              label: "Unavailable",
              color: Colors.grey,
              icon: Icons.block,
              onTap: () {
                AppSnackbar.showWarning(
                  title: "Unavailable",
                  message: "This offer is no longer active.",
                );
              },
            )
          else if (offer.canSubmitOffer)
            Obx(() {
              final isSubmitted =
                  controller.isOfferSubmitted(productId, offer: offer);
              return _ActionBtn(
                label: isSubmitted ? "Resubmit" : "Submit Offer",
                color: Theme.of(context).colorScheme.primary,
                icon: IconlyLight.send,
                onTap: () =>
                    _showInterestDialog(context, controller, productId, offer),
              );
            }),
        ],
      );
    }

    // For pending / interests tabs:
    final resolvedInterestId =
        offer.interestId ??
        (offer.id != null && offer.id != productId ? offer.id : null);

    if (offer.isConfirmed) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  "Deal Confirmed",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          _ActionBtn(
            label: "View",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
        ],
      );
    }

    if (offer.isRejected) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                SizedBox(width: 6),
                Text(
                  "Closed / Rejected",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          _ActionBtn(
            label: "View",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
        ],
      );
    }

    if (resolvedInterestId == null) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          _ActionBtn(
            label: "View",
            color: Colors.blue,
            icon: IconlyLight.show,
            onTap: () => _openDetails(offer, type),
          ),
          // Expired / out of stock is already shown in the status badge; no second copy here.
          if (offer.isExpired || offer.isOutOfStock)
            ...const <Widget>[]
          else if (!offer.isActive)
            _ActionBtn(
              label: "Unavailable",
              color: Colors.grey,
              icon: Icons.block,
              onTap: () {
                AppSnackbar.showWarning(
                  title: "Unavailable",
                  message: "This offer is no longer active.",
                );
              },
            )
          else if (offer.canSubmitOffer)
            _ActionBtn(
              label: "Show Interest",
              color: Theme.of(context).colorScheme.primary,
              icon: IconlyLight.star,
              onTap: () =>
                  _showInterestDialog(context, controller, productId, offer),
            ),
        ],
      );
    }

    final int effectiveInterestId = resolvedInterestId;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _ActionBtn(
          label: "View",
          color: Colors.blue,
          icon: IconlyLight.show,
          onTap: () => _openDetails(offer, type),
        ),
        _ActionBtn(
          label: "Negotiate",
          color: const Color(0xFFE65100),
          icon: IconlyLight.chat,
          onTap: () => Get.to(() => BuyerNegotiationView(offer: offer)),
        ),
        _ActionBtn(
          label: "Confirm Deal",
          color: Colors.green,
          icon: IconlyLight.tick_square,
          onTap: () => _showRemarkDialog(
            context,
            controller,
            "confirm",
            productId,
            effectiveInterestId,
          ),
        ),
        _ActionBtn(
          label: "Reject Interest",
          color: Colors.red,
          icon: IconlyLight.close_square,
          onTap: () => _showRemarkDialog(
            context,
            controller,
            "reject_interest",
            productId,
            effectiveInterestId,
          ),
        ),
      ],
    );
  }

  void _showInterestDialog(
    BuildContext context,
    BuyerOffersController controller,
    int productId,
    BuyerOfferModel offer,
  ) {
    if (!offer.canSubmitOffer ||
        offer.isOutOfStock ||
        !offer.isActive ||
        offer.isExpired) {
      AppSnackbar.showWarning(
        title: "Notice",
        message: offer.isOutOfStock
            ? "This item is currently out of stock."
            : (offer.isExpired
                ? "This deal has expired."
                : "This offer is no longer active."),
      );
      return;
    }

    // 1. Prefill quantity from available quantity, requested quantity, or display quantity
    String resolveInitialQty() {
      final rawAvail = (offer.availableQuantity ?? '')
          .replaceAll(RegExp(r'[^\d.]'), '')
          .trim();
      final rawReq = (offer.requestedQuantity ?? '')
          .replaceAll(RegExp(r'[^\d.]'), '')
          .trim();
      final rawDisp = (offer.displayQuantity ?? '')
          .replaceAll(RegExp(r'[^\d.]'), '')
          .trim();
      final numAvail = num.tryParse(rawAvail);
      if (numAvail != null && numAvail > 0) return rawAvail;
      final numReq = num.tryParse(rawReq);
      if (numReq != null && numReq > 0) return rawReq;
      final numDisp = num.tryParse(rawDisp);
      if (numDisp != null && numDisp > 0) return rawDisp;
      return rawAvail.isNotEmpty ? rawAvail : '';
    }

    final qtyCtrl = TextEditingController(text: resolveInitialQty());

    // 2. Prefill target price from offer price or display price
    final rawPriceCandidate = (offer.requestedAmount?.isNotEmpty == true)
        ? offer.requestedAmount!
        : (offer.displayPrice ?? '');
    final initialPrice = rawPriceCandidate
        .replaceAll('₹', '')
        .replaceAll(RegExp(r'[^\d.]'), '')
        .trim();
    final priceCtrl = TextEditingController(text: initialPrice);

    // 3. Prefill delivery destination matching web portal
    final defaultLocation =
        (offer.location != null && offer.location!.isNotEmpty)
        ? offer.location!
        : "AMR158M, Amalner, Maharashtra, India";
    final locationCtrl = TextEditingController(text: defaultLocation);
    final remarkCtrl = TextEditingController();

    // Delivery Period: starts as the buyer's current one, else the seller's offered one.
    DateTime? deliveryFrom = DeliveryPeriodPicker.parseUpcoming(
      offer.myDeliveryFrom ?? offer.deliveryFrom,
    );
    DateTime? deliveryTo = DeliveryPeriodPicker.parseUpcoming(
          offer.myDeliveryTo ?? offer.myDeliveryFrom ?? offer.deliveryTo,
        ) ??
        deliveryFrom;
    final offerPeriodText = DeliveryPeriodPicker.periodText(offer.deliveryFrom, offer.deliveryTo);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        elevation: 0,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);
            final isSubmitted =
                controller.isOfferSubmitted(productId, offer: offer);
            return GlassCard(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Text(
                      isSubmitted ? "Resubmit Offer" : "Submit Offer",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Submit your target quantity, price, and delivery details for this offer.",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Top Summary Card matching website modal
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Offer: ${offer.displayTitle}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Available: ${offer.displayQuantity}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pickup From: ${offer.pickupFrom?.isNotEmpty == true ? offer.pickupFrom! : 'N/A'}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Pickup To: ${offer.pickupTo?.isNotEmpty == true ? offer.pickupTo! : 'N/A'}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Offer Price *",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: priceCtrl,
                      hintText: "Enter price per unit",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Required Quantity *",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: qtyCtrl,
                      hintText: "Enter required quantity",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    // Buyers may ask for up to twice the available stock (MoM point 9).
                    if ((offer.maxQuantity ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        "You can ask for up to ${offer.maxQuantity} (twice the available quantity).",
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 12),

                    Text(
                      "Packing",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        "Bags are calculated automatically for bag-tracked seller stock.",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

DeliveryPeriodPicker(
                      from: deliveryFrom,
                      to: deliveryTo,
                      hint: offerPeriodText.isEmpty
                          ? null
                          : 'Seller delivery period: $offerPeriodText',
                      onChanged: (from, to) => setDialogState(() {
                        deliveryFrom = from;
                        deliveryTo = to;
                      }),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Loading To (Delivery Location) *",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: locationCtrl,
                      hintText:
                          "Enter delivery destination (e.g. City / Warehouse)",
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Condition (Remark)",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: remarkCtrl,
                      hintText: "Add remarks or quality expectations...",
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.brightness == Brightness.dark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFFE65100),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFFFB74D),
                              width: 1.2,
                            ),
                          ),
                          onPressed: () => Get.back(),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFFE65100),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            if (qtyCtrl.text.trim().isEmpty ||
                                priceCtrl.text.trim().isEmpty) {
                              AppSnackbar.showWarning(
                                title: "Required Fields",
                                message: "Please enter both quantity and price",
                              );
                              return;
                            }
                            if (deliveryFrom == null || deliveryTo == null) {
                              AppSnackbar.showWarning(
                                title: "Required Field",
                                message: "Please select the delivery period",
                              );
                              return;
                            }
                            Get.back();
                            await controller.submitInterest(
                              productId,
                              priceCtrl.text.trim(),
                              qtyCtrl.text.trim(),
                              remarkCtrl.text.trim(),
                              deliveryDate: DeliveryPeriodPicker.apiDate(deliveryFrom!),
                              deliveryDateTo: DeliveryPeriodPicker.apiDate(deliveryTo!),
                              loadingTo: locationCtrl.text.trim().isNotEmpty
                                  ? locationCtrl.text.trim()
                                  : null,
                              condition: remarkCtrl.text.trim().isNotEmpty
                                  ? remarkCtrl.text.trim()
                                  : null,
                              interestId: offer.interestId,
                            );
                          },
                          child: Text(
                            isSubmitted ? "Resubmit" : "Submit Offer",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
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
      ),
    );
  }

  void _showRemarkDialog(
    BuildContext context,
    BuyerOffersController controller,
    String action,
    int productId,
    int interestId,
  ) {
    final remarkCtrl = TextEditingController();
    final isConfirm = action == 'confirm';

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isConfirm ? "Confirm Deal" : "Reject Interest",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isConfirm
                    ? "Are you sure you want to finalize this deal?"
                    : "Are you sure you want to reject this offer interest?",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: remarkCtrl,
                hintText: "Enter remark...",
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConfirm ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final remark = remarkCtrl.text.trim();
                      Get.back();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        controller.performAction(
                          action,
                          productId,
                          interestId,
                          remark,
                        );
                      });
                    },
                    child: Text(isConfirm ? "Confirm" : "Reject"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = label.contains("Submit") || label.contains("Post");

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFF57C00) : color.withValues(alpha: 0.12),
          border: Border.all(
            color: isPrimary ? const Color(0xFFE65100) : color.withValues(alpha: 0.35),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isPrimary ? Colors.white : color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
