import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_negotiation_controller.dart';
import '../../common/seller_ui.dart';
import 'seller_interest_thread_view.dart';

class SellerOfferInterestsView extends StatelessWidget {
  const SellerOfferInterestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final productIdStr =
        Get.parameters['productId'] ?? (Get.arguments?.toString() ?? '0');
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (controller.interestsList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconlyLight.document,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No buyer interests yet for this offer",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SellerUi.statusChip(status),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Buyer Offer",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${item.buyerOfferedAmount ?? 'N/A'}",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Quantity Needed",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${item.buyerRequiredQuantity ?? 'N/A'} Qtl",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (item.buyerRemark != null &&
                          item.buyerRemark!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          "Buyer Remark: ${item.buyerRemark}",
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      if (item.counterPrice != null &&
                          item.counterPrice!.isNotEmpty) ...[
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
                              const Icon(
                                IconlyLight.swap,
                                size: 18,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Last Counter Offer: ₹${item.counterPrice} for ${item.counterQuantity} Qtl",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Keep the common thread for live counter proposals, but retain
                      // the seller's primary approve/reject controls on the interest
                      // card.  Otherwise a seller has to discover the action inside
                      // the thread and it looks like the actions are missing.
                      if (item.canSellerAction) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: item.id == null
                                    ? null
                                    : () => controller.rejectInterest(item.id!),
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('REJECT'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: item.id == null
                                    ? null
                                    : () =>
                                          controller.approveInterest(item.id!),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('ACCEPT'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (status == 'seller_confirmed' ||
                          status == 'buyer_confirmed')
                        Text(
                          status == 'seller_confirmed'
                              ? "You approved this interest. Waiting for the buyer to confirm."
                              : "Buyer confirmed. Waiting for admin to confirm the deal.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (item.canOpenNegotiation ||
                          const {
                            'deal_confirmed',
                            'rejected',
                            'cancelled',
                          }.contains(status))
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: item.id == null
                                ? null
                                : () => Get.to(
                                    () => SellerInterestThreadView(
                                      productId: productId,
                                      interestId: item.id!,
                                    ),
                                  )?.then((_) => controller.fetchInterests()),
                            icon: const Icon(
                              IconlyLight.time_circle,
                              size: 16,
                              color: primaryColor,
                            ),
                            label: Text(
                              item.canSellerAction
                                  ? "NEGOTIATE PRICE / QUANTITY"
                                  : "View negotiation history",
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: const BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
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
