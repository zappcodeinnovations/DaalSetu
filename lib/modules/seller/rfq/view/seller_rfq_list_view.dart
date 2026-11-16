import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../common/seller_ui.dart';
import '../controller/seller_rfq_controller.dart';
import '../model/seller_rfq_model.dart';
import 'seller_rfq_detail_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Buyer Requirements",
        subtitle: "Live demands & RFQs from verified buyers",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: controller.fetchRFQs,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: "Search by requirement title or ID...",
                prefixIcon: const Icon(
                  IconlyLight.search,
                  color: Color(0xFFE65100),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _statuses.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: controller.statusFilter.value == entry.key,
                          selectedColor: const Color(0xFFE65100).withValues(
                            alpha: 0.15,
                          ),
                          labelStyle: TextStyle(
                            color: controller.statusFilter.value == entry.key
                                ? const Color(0xFFE65100)
                                : (isDark ? Colors.white70 : Colors.grey.shade800),
                            fontWeight: controller.statusFilter.value == entry.key
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) => controller.setStatus(entry.key),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rfqList.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.fetchRFQs,
                color: const Color(0xFFE65100),
                child: controller.rfqList.isEmpty
                    ? SellerUi.emptyState("No buyer requirements found")
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rfqList.length,
                        itemBuilder: (context, index) =>
                            _card(context, controller.rfqList[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SellerRfqModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFFFE0B2).withValues(alpha: 0.7),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFFE65100).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.to(() => SellerRfqDetailView(rfqId: item.rfqId)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    SellerUi.statusChip(item.isQuoted ? 'quoted' : item.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${item.rfqId} • ${item.categoryName ?? 'Pulse'}${item.brandName != null ? ' • ${item.brandName}' : ''}",
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _metric(
                        "Target Price",
                        "₹${item.targetPrice ?? '-'} / ${item.priceUnit}",
                        highlight: true,
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        "Qty Needed",
                        "${item.requiredQuantity ?? '-'} ${item.quantityUnit}",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      IconlyLight.time_circle,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Expires: ${SellerUi.date(item.expiryDatetime)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                        ),
                      ),
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

  Widget _metric(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: highlight ? const Color(0xFFE65100) : null,
          ),
        ),
      ],
    );
  }
}
