import '../model/buyer_offer_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/buyer_offers_controller.dart';
import '../../../products/view/product_detail.dart';
import 'buyer_offer_details_view.dart';

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
              "Error: ${controller.errorMessage.value}",
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        final offers = controller.offersList;

        if (offers.isEmpty) {
          return const Center(child: Text("No interests found."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
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
                            color: _getStatusColor(offer.displayStatus ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            offer.displayStatus ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(offer.displayStatus ?? ''),
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
                    const Divider(height: 24),
                    Builder(
                      builder: (context) {
                        final pId = offer.productId ?? offer.id ?? 0;
                        final iId = offer.interestId ?? (offer.id != null && offer.id != pId ? offer.id! : pId);

                        if (offer.isConfirmed) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.withOpacity(0.25)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      "Deal Confirmed",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openDetails(offer),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(IconlyLight.show, size: 14),
                                label: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          );
                        }

                        if (offer.isRejected) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      "Interest Closed / Rejected",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openDetails(offer),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(color: Colors.blue),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(IconlyLight.show, size: 14),
                                label: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openDetails(offer),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              icon: const Icon(IconlyLight.show, size: 14),
                              label: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showNegotiateDialog(context, controller, pId, iId, offer),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text("NEGOTIATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showRemarkDialog(context, controller, "confirm", pId, iId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              icon: const Icon(Icons.check, size: 14, color: Colors.white),
                              label: const Text("CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            IconButton(
                              onPressed: () => _showRemarkDialog(context, controller, "reject_interest", pId, iId),
                              icon: const Icon(Icons.close, color: Colors.red, size: 20),
                              tooltip: "Reject Interest",
                            ),
                          ],
                        );
                      },
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

  Color _getStatusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('confirm')) return Colors.green;
    if (s.contains('accept')) return Colors.blue;
    if (s.contains('reject') || s.contains('cancel')) return Colors.red;
    return const Color(0xFFFFB300);
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
