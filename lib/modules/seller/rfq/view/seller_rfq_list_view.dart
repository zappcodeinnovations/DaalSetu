import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../common/seller_ui.dart';
import '../controller/seller_rfq_controller.dart';
import '../model/seller_rfq_model.dart';
import 'seller_rfq_detail_view.dart';

class SellerRfqListView extends StatelessWidget {
  const SellerRfqListView({super.key});

  static const _statuses = {
    'all': 'All',
    'open': 'Open',
    'negotiation_in_progress': 'Negotiation',
    'fulfilled': 'Fulfilled',
    'closed': 'Closed',
    'expired': 'Expired',
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerRfqController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: SellerUi.appBar(context, "Buyer Requirements"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: "Search by requirement title or ID...",
                prefixIcon: const Icon(IconlyLight.search, color: SellerUi.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _statuses.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: controller.statusFilter.value == entry.key,
                              selectedColor: SellerUi.primary.withValues(alpha: 0.25),
                              onSelected: (_) => controller.setStatus(entry.key),
                            ),
                          ))
                      .toList(),
                )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rfqList.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: SellerUi.primary));
              }
              return RefreshIndicator(
                onRefresh: controller.fetchRFQs,
                color: SellerUi.primary,
                child: controller.rfqList.isEmpty
                    ? SellerUi.emptyState("No buyer requirements found")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rfqList.length,
                        itemBuilder: (context, index) => _card(context, controller.rfqList[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SellerRfqModel item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => SellerRfqDetailView(rfqId: item.rfqId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SellerUi.statusChip(item.isQuoted ? 'quoted' : item.status),
                ],
              ),
              const SizedBox(height: 4),
              Text("${item.rfqId} • ${item.categoryName ?? 'Pulse'}${item.brandName != null ? ' • ${item.brandName}' : ''}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(child: _metric("Target Price", "₹${item.targetPrice ?? '-'} / ${item.priceUnit}", highlight: true)),
                  Expanded(child: _metric("Qty Needed", "${item.requiredQuantity ?? '-'} ${item.quantityUnit}")),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(IconlyLight.time_circle, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text("Expires: ${SellerUi.date(item.expiryDatetime)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Text(item.isQuoted ? "VIEW NEGOTIATION" : (item.canQuote ? "SUBMIT QUOTE" : "VIEW"),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SellerUi.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, fontSize: 14, color: highlight ? SellerUi.primary : null)),
      ],
    );
  }
}
