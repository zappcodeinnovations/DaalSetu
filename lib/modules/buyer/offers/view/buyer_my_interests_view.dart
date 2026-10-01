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
                  Row(
                    children: [
                      if (offer.status == 'requested') ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showActionDialog(context, "APPROVE", offer),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("APPROVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showActionDialog(context, "REJECT", offer),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                      if (offer.status == 'accepted')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showActionDialog(context, "CONFIRM", offer),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("CONFIRM DEAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                    ],
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

  void _showActionDialog(BuildContext context, String action, BuyerOfferModel offer) {
    final controller = Get.find<BuyerOffersController>(tag: 'interests');
    final remarkController = TextEditingController();

    Get.defaultDialog(
      title: "$action Offer",
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: remarkController,
          decoration: const InputDecoration(hintText: "Add a remark...", border: OutlineInputBorder()),
        ),
      ),
      textConfirm: "SUBMIT",
      buttonColor: action == "APPROVE" ? Colors.blue : (action == "REJECT" ? Colors.red : Colors.green),
      onConfirm: () {
        Get.back();
        if (action == "APPROVE") {
          controller.performAction('approve', offer.id!, offer.id!, remarkController.text);
        } else if (action == "REJECT") {
          controller.performAction('reject_interest', offer.id!, offer.id!, remarkController.text);
        } else {
          controller.performAction('confirm', offer.id!, offer.id!, remarkController.text);
        }
      },
      textCancel: "CANCEL",
    );
  }
}
