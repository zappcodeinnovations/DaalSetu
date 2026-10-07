import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../products/view/product_detail.dart';
import '../controller/buyer_offers_controller.dart';
import '../model/buyer_offer_model.dart';
import 'add_buyer_offer_view.dart';
import 'buyer_offer_details_view.dart';

class BuyerOffersView extends StatelessWidget {
  final int initialIndex;
  const BuyerOffersView({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 6,
      initialIndex: (initialIndex >= 0 && initialIndex < 6) ? initialIndex : 0,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(IconlyLight.arrow_left_2, color: theme.textTheme.bodyLarge?.color),
                  onPressed: () => Get.back(),
                )
              : null,
          title: Text(
            "Offers & Requirements",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(IconlyLight.plus, color: theme.colorScheme.primary),
              tooltip: "Post Requirement",
              onPressed: () => Get.to(() => const AddBuyerOfferScreen()),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Today"),
              Tab(text: "Pending"),
              Tab(text: "Previous"),
              Tab(text: "My Interests"),
              Tab(text: "My Requirements"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OfferList(offerType: 'all'),
            _OfferList(offerType: 'today'),
            _OfferList(offerType: 'pending'),
            _OfferList(offerType: 'previous'),
            _OfferList(offerType: 'interests'),
            _OfferList(offerType: 'requirements'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(IconlyLight.plus),
          label: Text("Post Requirement", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          onPressed: () => Get.to(() => const AddBuyerOfferScreen()),
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
        Get.to(() => ProductDetailScreen(productId: pId));
      } else if (offer.id != null) {
        Get.to(() => BuyerOfferDetailsView(offerId: offer.id!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BuyerOffersController(offerType: offerType), tag: offerType);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: TextField(
              onChanged: controller.searchOffers,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: offerType == 'requirements'
                    ? "Search requirements..."
                    : "Search offers (name, price, qty)...",
                hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(IconlyLight.search, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.allOffersList.isEmpty) {
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
                                : "No $offerType offers are available at the moment."),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (offerType == 'requirements' && !isSearching)
                        ElevatedButton.icon(
                          onPressed: () => Get.to(() => const AddBuyerOfferScreen()),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openDetails(offer, offerType),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  offer.displayTitle ?? 'Offer',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  offer.displayStatus ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
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
                          const SizedBox(height: 14),
                          _buildActionButtons(context, controller, offer, offerType),
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

  Widget _buildActionButtons(BuildContext context, BuyerOffersController controller, BuyerOfferModel offer, String type) {
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
          _ActionBtn(
            label: "Show Interest",
            color: Theme.of(context).colorScheme.primary,
            icon: IconlyLight.star,
            onTap: () => _showInterestDialog(context, controller, productId, offer),
          ),
        ],
      );
    }

    // For pending / interests tabs:
    final resolvedInterestId = offer.interestId ??
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
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  "Deal Confirmed",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
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
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                SizedBox(width: 6),
                Text(
                  "Closed / Rejected",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
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
          _ActionBtn(
            label: "Show Interest",
            color: Theme.of(context).colorScheme.primary,
            icon: IconlyLight.star,
            onTap: () => _showInterestDialog(context, controller, productId, offer),
          ),
        ],
      );
    }

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
          color: Colors.amber.shade700,
          icon: IconlyLight.chat,
          onTap: () => _showNegotiateDialog(context, controller, productId, resolvedInterestId, offer),
        ),
        _ActionBtn(
          label: "Confirm Deal",
          color: Colors.green,
          icon: IconlyLight.tick_square,
          onTap: () => _showRemarkDialog(context, controller, "confirm", productId, resolvedInterestId),
        ),
        _ActionBtn(
          label: "Reject Interest",
          color: Colors.red,
          icon: IconlyLight.close_square,
          onTap: () => _showRemarkDialog(context, controller, "reject_interest", productId, resolvedInterestId),
        ),
      ],
    );
  }

  void _showInterestDialog(BuildContext context, BuyerOffersController controller, int productId, BuyerOfferModel offer) {
    final qtyCtrl = TextEditingController(text: offer.requestedQuantity ?? '');
    final priceCtrl = TextEditingController(text: offer.requestedAmount ?? '');
    final remarkCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Show Interest",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  "Submit your target quantity and price for this offer.",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text("Requested Quantity", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: qtyCtrl,
                  hintText: "Enter quantity (e.g. 50)",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Text("Target Price (₹)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: priceCtrl,
                  hintText: "Enter price per unit",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Text("Remarks (Optional)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: remarkCtrl,
                  hintText: "Add any specific instructions...",
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
                      onPressed: () async {
                        if (qtyCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                          Get.snackbar("Required", "Please enter quantity and price", snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Get.back();
                        await controller.submitInterest(
                          productId,
                          priceCtrl.text.trim(),
                          qtyCtrl.text.trim(),
                          remarkCtrl.text.trim(),
                        );
                      },
                      child: const Text("Submit Interest"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNegotiateDialog(BuildContext context, BuyerOffersController controller, int productId, int interestId, BuyerOfferModel offer) {
    final msgCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: offer.requestedAmount ?? '');
    final qtyCtrl = TextEditingController(text: offer.requestedQuantity ?? '');

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Negotiate / Counter Offer",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  "Send a message or updated counter offer to the seller.",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text("Message", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GlassTextField(
                  controller: msgCtrl,
                  hintText: "Enter your message...",
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Counter Price (₹)", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          GlassTextField(
                            controller: priceCtrl,
                            hintText: "Price",
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Counter Qty", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          GlassTextField(
                            controller: qtyCtrl,
                            hintText: "Quantity",
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      onPressed: () async {
                        if (msgCtrl.text.trim().isEmpty) {
                          Get.snackbar("Required", "Please enter a message", snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Get.back();
                        await controller.sendNegotiation(
                          productId,
                          interestId,
                          msgCtrl.text.trim(),
                          priceCtrl.text.trim(),
                          qtyCtrl.text.trim(),
                        );
                      },
                      child: const Text("Send"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRemarkDialog(BuildContext context, BuyerOffersController controller, String action, int productId, int interestId) {
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
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
                      Get.back();
                      controller.performAction(action, productId, interestId, remarkCtrl.text);
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
