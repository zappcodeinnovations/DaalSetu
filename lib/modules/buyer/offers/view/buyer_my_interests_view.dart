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
import 'buyer_negotiation_view.dart';

class BuyerMyInterestsView extends StatelessWidget {
  const BuyerMyInterestsView({super.key});

  void _openDetails(BuyerOfferModel offer) {
    final pId = offer.productId ?? offer.id;
    if (pId != null) {
      Get.to(() => ProductDetailScreen(productId: pId));
    } else if (offer.id != null) {
      Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
    }
  }

  void _openNegotiation(BuyerOfferModel offer) {
    Get.to(() => BuyerNegotiationView(offer: offer));
  }

  void _showEditDialog(BuildContext context, BuyerOffersController controller, BuyerOfferModel offer) {
    final priceCandidate = (offer.requestedAmount?.isNotEmpty == true)
        ? offer.requestedAmount!
        : (offer.displayPrice ?? '');
    final cleanPrice = priceCandidate.replaceAll('₹', '').replaceAll(RegExp(r'[^\d.]'), '').trim();
    final cleanQty = (offer.requestedQuantity?.isNotEmpty == true ? offer.requestedQuantity! : (offer.displayQuantity ?? ''))
        .replaceAll(RegExp(r'[^\d.]'), '').trim();

    final priceCtrl = TextEditingController(text: cleanPrice);
    final qtyCtrl = TextEditingController(text: cleanQty);
    final locationCtrl = TextEditingController(text: offer.location ?? "AMR158M, Amalner, Maharashtra, India");
    final remarkCtrl = TextEditingController();

    DateTime? selectedDate;
    String? formattedDate;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                    Text("Edit Offer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text("Update your target quantity, price, and delivery details.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),

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
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                            formattedDate =
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
                              formattedDate ?? "dd-----yyyy",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: formattedDate != null ? null : Colors.grey,
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
                      hintText: "Enter destination address",
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
                              AppSnackbar.showWarning(title: "Required", message: "Please enter quantity and price");
                              return;
                            }
                            if (formattedDate == null || formattedDate!.isEmpty) {
                              AppSnackbar.showWarning(title: "Required", message: "Please select delivery date");
                              return;
                            }
                            Get.back();
                            await controller.submitInterest(
                              offer.productId ?? offer.id ?? 0,
                              priceCtrl.text.trim(),
                              qtyCtrl.text.trim(),
                              remarkCtrl.text.trim(),
                              deliveryDate: formattedDate,
                              loadingTo: locationCtrl.text.trim(),
                              condition: remarkCtrl.text.trim(),
                              interestId: offer.interestId,
                            );
                          },
                          child: const Text("Update Offer"),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BuyerOffersController(offerType: 'interests'), tag: 'interests');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "My Interests",
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
                    "No interests found.",
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
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isConfirmed = offer.isConfirmed;
              final isRejected = offer.isRejected;
              final isActionable = !isConfirmed && !isRejected;

              final status = offer.displayStatus ?? 'Interested';
              Color badgeColor = const Color(0xFFFFB300);
              if (isConfirmed) badgeColor = Colors.green;
              if (isRejected) badgeColor = Colors.red;

              // Display quantity
              final displayQty = (offer.displayQuantity != null && offer.displayQuantity!.isNotEmpty && offer.displayQuantity != 'N/A')
                  ? offer.displayQuantity!
                  : (offer.requestedQuantity?.isNotEmpty == true
                      ? "${offer.requestedQuantity} ${offer.quantityUnit ?? 'QTL'}"
                      : (offer.availableQuantity?.isNotEmpty == true
                          ? "${offer.availableQuantity} ${offer.quantityUnit ?? 'QTL'}"
                          : (offer.bagCount?.isNotEmpty == true ? "${offer.bagCount} Bags" : "0.000 QTL")));

              // Display price
              final displayPrice = offer.displayPrice?.isNotEmpty == true
                  ? offer.displayPrice!
                  : (offer.requestedAmount?.isNotEmpty == true ? "₹${offer.requestedAmount}" : "Open");

              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Transaction ID & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (offer.transactionId != null && offer.transactionId!.isNotEmpty) ...[
                                Text(
                                  offer.transactionId!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                offer.displayTitle ?? 'Offer',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Category, Brand & Seller chips
                    if (offer.category != null || offer.brand != null || offer.sellerName != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (offer.category != null && offer.category!.isNotEmpty && offer.category != offer.displayTitle)
                            _buildMetaChip(theme, Icons.grain, offer.category!),
                          if (offer.brand != null && offer.brand!.isNotEmpty)
                            _buildMetaChip(theme, Icons.branding_watermark_outlined, offer.brand!),
                          if (offer.sellerName != null && offer.sellerName!.isNotEmpty && offer.sellerName != '-')
                            _buildMetaChip(theme, IconlyLight.profile, "Seller: ${offer.sellerName!}"),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Stats Grid Card matching website columns
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
                                Text("Offered Amount", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  displayPrice,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: theme.dividerColor.withValues(alpha: 0.4)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Required Qty", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  displayQty,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                                ),
                              ],
                            ),
                          ),
                          if (offer.bagCount != null && offer.bagCount!.isNotEmpty) ...[
                            Container(width: 1, height: 32, color: theme.dividerColor.withValues(alpha: 0.4)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Bags", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${offer.bagCount} (${offer.packingWeight ?? '30'} kg)",
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Date & Timestamp
                    if (offer.createdAt != null && offer.createdAt!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(IconlyLight.time_circle, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Interest Date: ${offer.createdAt!}",
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 20),

                    // Action buttons row: [ View ] [ Edit ] [ Negotiation ]
                    Row(
                      children: [
                        // 1. View Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openDetails(offer),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textTheme.bodyLarge?.color,
                              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text("View", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Edit Button (if active)
                        if (isActionable) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showEditDialog(context, controller, offer),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // 3. Negotiation Button
                        Expanded(
                          flex: isActionable ? 1 : 2,
                          child: ElevatedButton(
                            onPressed: () => _openNegotiation(offer),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE65100),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_outlined, size: 14),
                                SizedBox(width: 4),
                                Text("Negotiation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
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
      }),
    );
  }

  Widget _buildMetaChip(ThemeData theme, IconData icon, String label) {
    if (label.trim().isEmpty || (label.startsWith('{') && label.endsWith('}'))) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }
}
