import 'package:daalsetu/widgets/offer_media_viewer.dart';
import 'package:daalsetu/widgets/page_auto_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../widgets/authenticated_network_image.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import '../../../products/view/product_detail.dart';
import 'buyer_offer_details_view.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/utils/app_date.dart';

class BuyerTodayOffersView extends StatelessWidget {
  const BuyerTodayOffersView({super.key});

  Widget _buildHeartBadge(String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 11, color: Colors.redAccent),
          const SizedBox(width: 3),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
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
        sUpper.contains('DISABLED');
    final isWarning = !isOutOfStock &&
        (sUpper.contains('NEGOTIAT') ||
            sUpper.contains('PENDING') ||
            sUpper.contains('INTEREST'));

    final color = isGood
        ? Colors.green
        : (isBad
            ? Colors.red
            : (isWarning
                ? const Color(0xFFF59E0B)
                : theme.colorScheme.primary));

    String displayStatus = status;
    if (sUpper.contains('EXPIRED')) {
      displayStatus = 'Deal Expired';
    } else if (isOutOfStock) {
      displayStatus = 'OUT OF STOCK';
    } else if (status.trim().toUpperCase() == 'AVAILABLE') {
      displayStatus = 'ACTIVE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, IconData icon, String text) {
    if (text.trim().isEmpty || (text.startsWith('{') && text.endsWith('}'))) {
      return const SizedBox.shrink();
    }
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

  Future<void> _openMediaThenDetails(BuyerOfferModel offer) async {
    final productId = offer.productId;
    if (!offer.isRfq && productId != null && productId > 0) {
      final opened = await openOfferMediaForProduct(productId, title: offer.displayTitle ?? 'Offer');
      if (opened) return;
    }
    _openDetails(offer);
  }

  void _openDetails(BuyerOfferModel offer) {
    final pId = offer.productId ?? offer.id;
    if (pId != null) {
      Get.to(() => ProductDetailScreen(
            productId: pId,
            onSubmitOffer: buyerSubmitOfferCallback(offer, tag: 'today'),
          ));
    } else if (offer.id != null) {
      Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
    }
  }

  @override
  Widget build(BuildContext context) => PageAutoRefresh(
    onRefresh: () => Get.find<BuyerOffersController>(tag: 'today').fetchOffers(silent: true),
    child: _buildPageContent(context),
  );

  Widget _buildPageContent(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BuyerOffersController(offerType: 'today'), tag: 'today');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        leading: AppBarLeading(
          child: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Get.back(),
                )
              : null,
        ),
        title: "Today's Offers",
        subtitle: "Fresh commodity listings posted today",
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
          return const Center(child: Text("No offers found for today."));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final isDark = theme.brightness == Brightness.dark;
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

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openDetails(offer),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header: Thumbnail + Title/Code/Brand + Heart + Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image thumbnail / NO MEDIA box. Tap = open the photo / video right away.
                        GestureDetector(
                          key: Key('buyer_today_offer_media_${offer.id}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openMediaThenDetails(offer),
                          child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                          ),
                          child: (offer.imageUrl != null && offer.imageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AuthenticatedNetworkImage(
                                    url: offer.imageUrl!,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    fallback: _buildNoMediaPlaceholder(theme),
                                  ),
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
                              // Row 1: Title (Full remaining width) + Heart badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      offer.displayTitle ?? 'Offer',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildHeartBadge(offer.interestCount ?? '0'),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Row 2: Status & Code & Brand in a responsive Wrap
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildStatusBadge(offer.displayStatus ?? 'ACTIVE', theme),
                                  if (offer.code != null && offer.code!.isNotEmpty)
                                    Text(
                                      offer.code!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  if (offer.brand != null && offer.brand!.isNotEmpty && offer.brand != offer.displayTitle)
                                    Text(
                                      offer.brand!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Main Highlights Box: Available Quantity & Offer Price
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
                            child: Row(
                              children: [
                                Icon(IconlyLight.buy, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Available Quantity",
                                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                      ),
                                      Text(
                                        displayQtyStr,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: theme.dividerColor.withValues(alpha: 0.4)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(IconlyLight.wallet, size: 20, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Offer Price",
                                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                                      ),
                                      Text(
                                        offer.displayPrice?.isNotEmpty == true
                                            ? offer.displayPrice!
                                            : (offer.requestedAmount?.isNotEmpty == true
                                                ? "₹${offer.requestedAmount}/${(offer.amountUnit ?? offer.quantityUnit ?? 'QTL').toUpperCase()}"
                                                : 'Open'),
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
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

                    // Metadata Chips: Variety, Bags/Packing, Pickup, Location
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (offer.category != null && offer.category!.isNotEmpty && offer.category != offer.title)
                          _buildBadge(theme, Icons.grain, offer.category!),
                        if (offer.bagCount != null && offer.bagCount!.isNotEmpty)
                          _buildBadge(
                            theme,
                            IconlyLight.work,
                            "${offer.bagCount} Bags${offer.packingWeight != null && offer.packingWeight!.isNotEmpty ? " (${offer.packingWeight} kg)" : ""}",
                          ),
                        if (offer.pickupFrom != null && offer.pickupFrom!.isNotEmpty)
                          _buildBadge(
                            theme,
                            IconlyLight.calendar,
                            "Pickup: ${offer.pickupFrom}${offer.pickupTo != null && offer.pickupTo!.isNotEmpty ? " - ${offer.pickupTo}" : ""}",
                          ),
                        if (offer.location != null && offer.location!.isNotEmpty)
                          _buildBadge(theme, IconlyLight.location, offer.location!),
                        if (offer.sellerName != null && offer.sellerName!.isNotEmpty)
                          _buildBadge(theme, Icons.storefront_outlined, offer.sellerName!),
                      ],
                    ),

                    const Divider(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDetails(offer),
                            icon: Icon(
                              IconlyLight.show,
                              size: 15,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            label: Text(
                              "View Details",
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(40),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFFFE0B2),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        // Expired / out of stock is already in the status badge: no second copy.
                        if (!offer.isExpired && !offer.isOutOfStock) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: offer.isExpired
                                  ? () {
                                      AppSnackbar.showError(
                                        message: "Deal has expired. You cannot show interest.",
                                      );
                                    }
                                  : (offer.isOutOfStock
                                      ? () {
                                          AppSnackbar.showWarning(
                                            title: "Out of Stock",
                                            message:
                                                "This item is currently out of stock. You cannot submit an offer.",
                                          );
                                        }
                                      : (!offer.isActive
                                          ? () {
                                              AppSnackbar.showWarning(
                                                title: "Unavailable",
                                                message:
                                                    "This offer is no longer active.",
                                              );
                                            }
                                          : (offer.canSubmitOffer
                                              ? () => _showInterestDialog(
                                                  context,
                                                  controller,
                                                  offer.productId ?? offer.id ?? 0,
                                                  offer)
                                              : null))),
                              icon: Icon(
                                offer.isExpired
                                    ? Icons.timer_off_outlined
                                    : (offer.isOutOfStock
                                        ? Icons.remove_shopping_cart_outlined
                                        : (!offer.isActive
                                            ? Icons.block
                                            : IconlyLight.send)),
                                size: 15,
                                color: Colors.white,
                              ),
                              label: Obx(() {
                                final pId = offer.productId ?? offer.id ?? 0;
                                final isSubmitted =
                                    controller.isOfferSubmitted(pId, offer: offer);
                                return Text(
                                  offer.isExpired
                                      ? "Deal Expired"
                                      : (offer.isOutOfStock
                                          ? "Out of Stock"
                                          : (!offer.isActive
                                              ? "Unavailable"
                                              : (isSubmitted
                                                  ? "Resubmit"
                                                  : "Submit Offer"))),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: offer.canSubmitOffer
                                    ? const Color(0xFFE65100)
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade500,
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size.fromHeight(40),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildNoMediaPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.grain, size: 20, color: theme.dividerColor.withValues(alpha: 0.8)),
        const SizedBox(height: 2),
        Text(
          "NO MEDIA",
          style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.grey),
        ),
      ],
    );
  }

  void _showInterestDialog(BuildContext context, BuyerOffersController controller, int productId, BuyerOfferModel offer) {
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
      final rawAvail = (offer.availableQuantity ?? '').replaceAll(RegExp(r'[^\d.]'), '').trim();
      final rawReq = (offer.requestedQuantity ?? '').replaceAll(RegExp(r'[^\d.]'), '').trim();
      final rawDisp = (offer.displayQuantity ?? '').replaceAll(RegExp(r'[^\d.]'), '').trim();
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
    final initialPrice = rawPriceCandidate.replaceAll('₹', '').replaceAll(RegExp(r'[^\d.]'), '').trim();
    final priceCtrl = TextEditingController(text: initialPrice);

    // 3. Prefill delivery destination matching web portal
    final defaultLocation = (offer.location != null && offer.location!.isNotEmpty)
        ? offer.location!
        : "AMR158M, Amalner, Maharashtra, India";
    final locationCtrl = TextEditingController(text: defaultLocation);
    final remarkCtrl = TextEditingController();

    DateTime? selectedDeliveryDate;
    String? formattedDeliveryDate;

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
                    Text(
                      isSubmitted ? "Resubmit Offer" : "Submit Offer",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Submit your target quantity, price, and delivery details for this offer.",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),

                    // Top Summary Card matching website modal
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
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
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Available: ${offer.displayQuantity}",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pickup From: ${offer.pickupFrom?.isNotEmpty == true ? offer.pickupFrom! : 'N/A'}",
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                "Pickup To: ${offer.pickupTo?.isNotEmpty == true ? offer.pickupTo! : 'N/A'}",
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text("Offer Price *", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: priceCtrl,
                      hintText: "Enter price per unit",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    Text("Required Quantity *", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: qtyCtrl,
                      hintText: "Enter required quantity",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    Text("Packing", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        "Bags are calculated automatically for bag-tracked seller stock.",
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text("Delivery Date *", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDeliveryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDeliveryDate = picked;
                            formattedDeliveryDate =
                                AppDate.fromDateTime(picked);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDeliveryDate ?? "dd/mm/yyyy",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: formattedDeliveryDate != null ? null : Colors.grey,
                              ),
                            ),
                            const Icon(IconlyLight.calendar, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text("Loading To (Delivery Location) *", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    GlassTextField(
                      controller: locationCtrl,
                      hintText: "Enter delivery destination (e.g. City / Warehouse)",
                    ),
                    const SizedBox(height: 12),

                    Text("Condition (Remark)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
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
                            if (qtyCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                              AppSnackbar.showWarning(title: "Required Fields", message: "Please enter both quantity and price");
                              return;
                            }
                            if (formattedDeliveryDate == null || formattedDeliveryDate!.isEmpty) {
                              AppSnackbar.showWarning(title: "Required Field", message: "Please select a preferred delivery date");
                              return;
                            }
                            Get.back();
                            await controller.submitInterest(
                              productId,
                              priceCtrl.text.trim(),
                              qtyCtrl.text.trim(),
                              remarkCtrl.text.trim(),
                              deliveryDate: formattedDeliveryDate,
                              loadingTo: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : null,
                              condition: remarkCtrl.text.trim().isNotEmpty ? remarkCtrl.text.trim() : null,
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
                        const SizedBox(width: 12),
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
}
