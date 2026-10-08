import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import '../../../products/view/product_detail.dart';
import 'buyer_offer_details_view.dart';

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
    final sUpper = status.toUpperCase();
    final isGood = sUpper.contains('ACTIVE') ||
        sUpper.contains('AVAILABLE') ||
        sUpper.contains('OPEN') ||
        sUpper.contains('CONFIRM') ||
        sUpper.contains('DEAL CONFIRMED');
    final isBad = sUpper.contains('EXPIRED') ||
        sUpper.contains('REJECT') ||
        sUpper.contains('CANCEL') ||
        sUpper.contains('CLOSED');
    final isWarning = sUpper.contains('NEGOTIAT') || sUpper.contains('PENDING') || sUpper.contains('INTEREST');

    final color = isGood
        ? Colors.green
        : (isBad
            ? Colors.red
            : (isWarning
                ? const Color(0xFFF59E0B)
                : theme.colorScheme.primary));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
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

  void _openDetails(BuyerOfferModel offer) {
    final pId = offer.productId ?? offer.id;
    if (pId != null) {
      Get.to(() => ProductDetailScreen(productId: pId));
    } else if (offer.id != null) {
      Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BuyerOffersController(offerType: 'today'), tag: 'today');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Today's Offers",
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
          return const Center(child: Text("No offers found for today."));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final offer = offers[index];
            final displayQtyStr = (offer.displayQuantity != null &&
                    offer.displayQuantity!.isNotEmpty &&
                    offer.displayQuantity != 'N/A')
                ? offer.displayQuantity!
                : (offer.availableQuantity?.isNotEmpty == true
                    ? "${offer.availableQuantity} ${offer.quantityUnit ?? 'QTL'}"
                    : (offer.requestedQuantity?.isNotEmpty == true
                        ? "${offer.requestedQuantity} ${offer.quantityUnit ?? 'QTL'}"
                        : (offer.bagCount?.isNotEmpty == true
                            ? "${offer.bagCount} Bags"
                            : "0.000 QTL")));

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
                        // Image thumbnail / NO MEDIA box
                        Container(
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
                                  child: Image.network(
                                    offer.imageUrl!,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildNoMediaPlaceholder(theme),
                                  ),
                                )
                              : _buildNoMediaPlaceholder(theme),
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
                            icon: const Icon(IconlyLight.show, size: 16),
                            label: const Text("View Details"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showInterestDialog(context, controller, offer.productId ?? offer.id ?? 0, offer),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(IconlyLight.send, size: 16, color: Colors.white),
                            label: const Text("Submit Offer", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
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
            return GlassCard(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Submit Offer",
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
                                "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
                              formattedDeliveryDate ?? "dd-----yyyy",
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
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
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
                          child: const Text("Submit Offer"),
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
