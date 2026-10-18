import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/app_snackbar.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import 'buyer_offer_details_view.dart';
import 'buyer_negotiation_view.dart';

class BuyerMyInterestsView extends StatelessWidget {
  final bool showAppBar;
  const BuyerMyInterestsView({super.key, this.showAppBar = true});

  void _openDetails(BuyerOfferModel offer) {
    final pId = offer.productId ?? offer.id;
    if (pId != null) {
      Get.to(
        () => BuyerOfferDetailsView(
          offerId: pId,
          productId: offer.productId,
          interestId: offer.interestId,
        ),
      );
    } else if (offer.id != null) {
      Get.to(
        () => BuyerOfferDetailsView(
          offerId: offer.id!,
          productId: offer.productId,
          interestId: offer.interestId,
        ),
      );
    }
  }

  void _openNegotiation(BuyerOfferModel offer) {
    Get.to(() => BuyerNegotiationView(offer: offer));
  }

  Future<void> _cancelInterest(
    BuildContext context,
    BuyerOffersController controller,
    BuyerOfferModel offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel interest?'),
        content: const Text(
          'This interest will be closed and cannot be edited afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel interest'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.cancelInterest(
      offer.productId ?? offer.id ?? 0,
      offer.interestId ?? 0,
    );
  }

  void _showEditDialog(
    BuildContext context,
    BuyerOffersController controller,
    BuyerOfferModel offer,
  ) {
    final priceCandidate = (offer.requestedAmount?.isNotEmpty == true)
        ? offer.requestedAmount!
        : (offer.displayPrice ?? '');
    final cleanPrice = priceCandidate
        .replaceAll('₹', '')
        .replaceAll(RegExp(r'[^\d.]'), '')
        .trim();
    final cleanQty =
        (offer.requestedQuantity?.isNotEmpty == true
                ? offer.requestedQuantity!
                : (offer.displayQuantity ?? ''))
            .replaceAll(RegExp(r'[^\d.]'), '')
            .trim();

    String formatDisplay(DateTime dt) =>
        "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";

    final loadingFromText = (offer.pickupFrom?.isNotEmpty == true)
        ? offer.pickupFrom!
        : (offer.location?.isNotEmpty == true
            ? offer.location!
            : "Shop no 12, krishna mandir, Bhopal, Bhopal, Madhya Pradesh, India");

    final initialLoadingTo = (offer.pickupTo?.isNotEmpty == true)
        ? offer.pickupTo!
        : (offer.location?.isNotEmpty == true
            ? offer.location!
            : "AMR158M, Amalner, Maharashtra, India");

    final priceCtrl = TextEditingController(text: cleanPrice);
    final qtyCtrl = TextEditingController(text: cleanQty);
    final locationCtrl = TextEditingController(text: initialLoadingTo);
    final remarkCtrl = TextEditingController();

    DateTime? selectedDate;
    String? formattedDate;
    String? displayDateText;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final theme = Theme.of(dialogContext);
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE65100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Edit Offer / Interest",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () => Get.back(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Offered Amount (Rate)
                            Text(
                              "Offered Amount (Rate) (₹) *",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GlassTextField(
                              controller: priceCtrl,
                              hintText: "Enter rate per unit",
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Required Quantity (QTL)
                            Text(
                              "Required Quantity (QTL) *",
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
                            const SizedBox(height: 14),

                            // Loading From (Read-only matching web)
                            Text(
                              "Loading From",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.disabledColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                loadingFromText,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Loading To
                            Text(
                              "Loading To *",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GlassTextField(
                              controller: locationCtrl,
                              hintText: "Enter destination address",
                            ),
                            const SizedBox(height: 14),

                            // Delivery Date
                            Text(
                              "Delivery Date *",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = picked;
                                    formattedDate =
                                        "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year.toString().padLeft(4, '0')}";
                                    displayDateText = formatDisplay(picked);
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      displayDateText ?? "dd-mm-yyyy",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: displayDateText != null
                                            ? null
                                            : Colors.grey,
                                      ),
                                    ),
                                    const Icon(IconlyLight.calendar, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Buyer Remark
                            Text(
                              "Buyer Remark",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GlassTextField(
                              controller: remarkCtrl,
                              hintText: "Add remarks or instructions...",
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Get.back(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (qtyCtrl.text.trim().isEmpty ||
                                        priceCtrl.text.trim().isEmpty) {
                                      AppSnackbar.showWarning(
                                        title: "Required",
                                        message: "Please enter quantity and price",
                                      );
                                      return;
                                    }
                                    if (formattedDate == null ||
                                        formattedDate!.isEmpty) {
                                      AppSnackbar.showWarning(
                                        title: "Required",
                                        message: "Please select delivery date",
                                      );
                                      return;
                                    }
                                    final prodId = (offer.productId != null && offer.productId! > 0)
                                        ? offer.productId!
                                        : ((offer.id != null && offer.id != offer.interestId)
                                            ? offer.id!
                                            : (offer.interestId ?? 0));
                                    final intId = (offer.interestId != null && offer.interestId! > 0)
                                        ? offer.interestId!
                                        : (offer.id ?? 0);

                                    Get.back();
                                    await controller.submitInterest(
                                      prodId,
                                      priceCtrl.text.trim(),
                                      qtyCtrl.text.trim(),
                                      remarkCtrl.text.trim(),
                                      deliveryDate: formattedDate,
                                      loadingTo: locationCtrl.text.trim(),
                                      condition: remarkCtrl.text.trim(),
                                      interestId: intId,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC0392B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Save Changes"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    final controller = Get.put(
      BuyerOffersController(offerType: 'interests'),
      tag: 'interests',
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.textTheme.bodyLarge?.color,
                        size: 20,
                      ),
                      onPressed: () => Get.back(),
                    )
                  : null,
              title: Text(
                "My Interests",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            )
          : null,
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
              final status = offer.displayStatus ?? 'Interested';
              final isInterestedCard =
                  status.trim().toLowerCase() == 'interested' ||
                  (offer.status ?? '').trim().toLowerCase() == 'interested' ||
                  offer.isInterested ||
                  offer.canEditInterest;
              Color badgeColor = const Color(0xFFFFB300);
              if (isConfirmed) badgeColor = Colors.green;
              if (isRejected) badgeColor = Colors.red;

              // Display quantity
              final displayQty =
                  (offer.displayQuantity != null &&
                      offer.displayQuantity!.isNotEmpty &&
                      offer.displayQuantity != 'N/A')
                  ? offer.displayQuantity!
                  : (offer.requestedQuantity?.isNotEmpty == true
                        ? "${offer.requestedQuantity} ${offer.quantityUnit ?? 'QTL'}"
                        : (offer.availableQuantity?.isNotEmpty == true
                              ? "${offer.availableQuantity} ${offer.quantityUnit ?? 'QTL'}"
                              : (offer.bagCount?.isNotEmpty == true
                                    ? "${offer.bagCount} Bags"
                                    : "0.000 QTL")));

              // Display price
              final displayPrice = offer.displayPrice?.isNotEmpty == true
                  ? offer.displayPrice!
                  : (offer.requestedAmount?.isNotEmpty == true
                        ? "₹${offer.requestedAmount}"
                        : "Open");

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
                              if (offer.transactionId != null &&
                                  offer.transactionId!.isNotEmpty) ...[
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.3),
                            ),
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
                    if (offer.category != null ||
                        offer.brand != null ||
                        offer.sellerName != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (offer.category != null &&
                              offer.category!.isNotEmpty &&
                              offer.category != offer.displayTitle)
                            _buildMetaChip(theme, Icons.grain, offer.category!),
                          if (offer.brand != null && offer.brand!.isNotEmpty)
                            _buildMetaChip(
                              theme,
                              Icons.branding_watermark_outlined,
                              offer.brand!,
                            ),
                          if (offer.sellerName != null &&
                              offer.sellerName!.isNotEmpty &&
                              offer.sellerName != '-')
                            _buildMetaChip(
                              theme,
                              IconlyLight.profile,
                              "Seller: ${offer.sellerName!}",
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Stats Grid Card matching website columns
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Offered Amount",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayPrice,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: theme.dividerColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Required Qty",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayQty,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (offer.bagCount != null &&
                              offer.bagCount!.isNotEmpty) ...[
                            Container(
                              width: 1,
                              height: 32,
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bags",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${offer.bagCount} (${offer.packingWeight ?? '30'} kg)",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
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
                    if (offer.createdAt != null &&
                        offer.createdAt!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            IconlyLight.time_circle,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Interest Date: ${offer.createdAt!}",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 20),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _openDetails(offer),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            side: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.6),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "View",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isInterestedCard)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showEditDialog(context, controller, offer),
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: const Text(
                              "Edit",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (offer.canCancelInterest && isInterestedCard)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _cancelInterest(context, controller, offer),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            icon: const Icon(Icons.close, size: 15),
                            label: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (!offer.isConfirmed && !isRejected)
                          ElevatedButton.icon(
                            onPressed: () => _openNegotiation(offer),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE65100),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.chat_outlined, size: 15),
                            label: const Text(
                              "Negotiation",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
    if (label.trim().isEmpty ||
        (label.startsWith('{') && label.endsWith('}'))) {
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
            style: GoogleFonts.inter(
              fontSize: 10,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
