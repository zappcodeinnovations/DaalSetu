import '../model/buyer_offer_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/buyer_offers_controller.dart';

class BuyerMyInterestsView extends StatelessWidget {
  const BuyerMyInterestsView({super.key});

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
            return GlassCard(
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
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showNegotiateDialog(context, controller, pId, iId, offer),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text("NEGOTIATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRemarkDialog(context, controller, "confirm", pId, iId),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              icon: const Icon(Icons.check, size: 14, color: Colors.white),
                              label: const Text("CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 8),
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
            );
          },
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('confirm')) return Colors.green;
    if (status.contains('accept')) return Colors.blue;
    if (status.contains('reject') || status.contains('cancel')) return Colors.red;
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
