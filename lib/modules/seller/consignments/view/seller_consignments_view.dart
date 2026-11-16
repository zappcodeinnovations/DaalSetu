import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import '../../contracts/view/seller_contract_detail_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';

/// Consignment management (single API: /api/consignments/).
class SellerConsignmentController extends GetxController {
  var isLoading = false.obs;
  var rows = <Map<String, dynamic>>[].obs;
  var workflowStatus = 'all'.obs;
  var search = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
    debounce(search, (_) => fetch(), time: const Duration(milliseconds: 400));
  }

  Future<void> fetch() async {
    try {
      isLoading(true);
      final data = await SellerServices.getConsignments(
        workflowStatus: workflowStatus.value == 'all' ? null : workflowStatus.value,
        search: search.value,
      );
      rows.value = (data['results'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      SellerUi.error(e);
    } finally {
      isLoading(false);
    }
  }

  void setStatus(String status) {
    workflowStatus.value = status;
    fetch();
  }

  Future<void> markReady(Map<String, dynamic> row) async {
    final ok = await SellerUi.confirm(
      "Ready for Loading",
      "Mark contract ${row['contract_id']} ready? Transporters will be able to bid on it.",
      confirmText: "Mark Ready",
    );
    if (!ok) return;
    final result = await SellerUi.run(() => SellerServices.consignmentAction(row['id'] as int, 'ready_for_loading'));
    if (result != null) fetch();
  }
}

class SellerConsignmentsView extends StatelessWidget {
  const SellerConsignmentsView({super.key});

  static const _filters = {
    'all': 'All',
    'pending': 'Pending',
    'ready': 'Ready',
    'dispatch': 'Dispatched',
    'received': 'Received',
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerConsignmentController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Consignments",
        subtitle: "Stock consignments & warehouse dispatch tracking",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: controller.fetch,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => controller.search.value = val,
              decoration: InputDecoration(
                hintText: "Search contract, product, location...",
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(IconlyLight.search, color: Color(0xFFFFB300)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _filters.entries
                      .map((entry) {
                        final isSelected = controller.workflowStatus.value == entry.key;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => controller.setStatus(entry.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : (isDark ? const Color(0xFF282828) : Colors.grey.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.withValues(alpha: 0.2)),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rows.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: SellerUi.primary));
              }
              return RefreshIndicator(
                color: SellerUi.primary,
                onRefresh: controller.fetch,
                child: controller.rows.isEmpty
                    ? SellerUi.emptyState("No consignments found", icon: IconlyLight.buy)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: controller.rows.length,
                        itemBuilder: (context, index) => _card(context, controller, controller.rows[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SellerConsignmentController controller, Map<String, dynamic> row) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stage = row['status'] == 'received'
        ? 'received'
        : row['is_dispatched'] == true
            ? 'dispatched'
            : row['transporter_visible_at'] != null
                ? 'ready'
                : 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.to(() => SellerContractDetailView(contractId: row['id'] as int))
              ?.then((_) => controller.fetch()),
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
                        "Contract #${row['contract_id']}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                    ),
                    SellerUi.statusChip(stage),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${row['product_title'] ?? '-'} • Buyer ${row['display_buyer_id'] ?? '-'}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                // Route visualization tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282828) : const Color(0xFFFFF8E1).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${row['loading_from'] ?? '-'} → ${row['loading_to'] ?? '-'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade200 : const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SellerUi.infoRow("Quantity", "${row['deal_quantity'] ?? '-'} ${row['quantity_unit'] ?? ''}"),
                SellerUi.infoRow("Trade Value", SellerUi.money(row['trade_value'])),
                SellerUi.infoRow("Transporter", row['assigned_transporter']?.toString()),
                if (row['can_mark_ready'] == true) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => controller.markReady(row),
                      icon: const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                      label: Text(
                        "MARK READY FOR LOADING",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
