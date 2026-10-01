import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_negotiation_controller.dart';
import 'seller_counter_offer_dialog.dart';

class SellerOfferInterestsView extends StatelessWidget {
  const SellerOfferInterestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final productIdStr = Get.parameters['productId'] ?? (Get.arguments?.toString() ?? '0');
    final productId = int.tryParse(productIdStr) ?? 0;

    final controller = Get.put(
      SellerNegotiationController(productId: productId),
      tag: 'seller_negotiation_$productId',
    );

    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Buyer Interests & Offers",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (controller.interestsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.document, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  "No buyer interests yet for this offer",
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchInterests,
          color: primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.interestsList.length,
            itemBuilder: (context, index) {
              final item = controller.interestsList[index];
              final status = (item.status ?? 'requested').toLowerCase();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.buyerName ?? "Buyer #${item.id}",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'confirmed'
                                  ? Colors.green.shade100
                                  : (status == 'rejected' ? Colors.red.shade100 : Colors.amber.shade100),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == 'confirmed'
                                    ? Colors.green.shade800
                                    : (status == 'rejected' ? Colors.red.shade800 : Colors.amber.shade900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Buyer Offer", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${item.buyerOfferedAmount ?? 'N/A'}",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Quantity Needed", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.buyerRequiredQuantity ?? 'N/A'} Qtl",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (item.buyerRemark != null && item.buyerRemark!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Buyer Remark: ${item.buyerRemark}",
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      ],
                      if (item.counterPrice != null && item.counterPrice!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(IconlyLight.swap, size: 18, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Last Counter Offer: ₹${item.counterPrice} for ${item.counterQuantity} Qtl",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => SellerCounterOfferDialog.show(context, controller, item),
                              icon: const Icon(IconlyLight.chat, size: 16),
                              label: const Text("COUNTER"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => controller.confirmDeal(item.id!),
                              icon: const Icon(Icons.check, size: 16, color: Colors.white),
                              label: const Text("CONFIRM DEAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        );
      }),
    );
  }
}
