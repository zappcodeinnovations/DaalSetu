import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../controller/seller_rfq_controller.dart';
import 'seller_submit_quote_dialog.dart';

class SellerRfqListView extends StatelessWidget {
  const SellerRfqListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerRfqController());
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Buyer Requirements (RFQs)",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) {
                controller.searchQuery.value = val;
                controller.fetchRFQs();
              },
              decoration: InputDecoration(
                hintText: "Search requirement by commodity or buyer...",
                prefixIcon: const Icon(IconlyLight.search, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: primaryColor));
              }

              if (controller.rfqList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.document, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("No buyer requirements found", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchRFQs,
                color: primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.rfqList.length,
                  itemBuilder: (context, index) {
                    final item = controller.rfqList[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    item.categoryName ?? "Pulse Requirement",
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.isQuoted == true ? Colors.blue.shade100 : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.isQuoted == true ? "QUOTED" : "OPEN FOR QUOTE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.isQuoted == true ? Colors.blue.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Buyer: ${item.buyerName ?? 'Anonymous Buyer'}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Target Price", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        "₹${item.targetPrice ?? 'N/A'} / ${item.unit ?? 'Qtl'}",
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Qty Needed", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${item.requiredQuantity ?? 'N/A'} ${item.unit ?? 'Qtl'}",
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item.deliveryLocation != null && item.deliveryLocation!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(IconlyLight.location, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Delivery Location: ${item.deliveryLocation}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => SellerSubmitQuoteDialog.show(context, controller, item),
                                icon: const Icon(IconlyLight.send, size: 16, color: Colors.white),
                                label: Text(
                                  item.isQuoted == true ? "UPDATE QUOTE" : "SUBMIT SELLER QUOTE",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          ),
        ],
      ),
    );
  }
}
