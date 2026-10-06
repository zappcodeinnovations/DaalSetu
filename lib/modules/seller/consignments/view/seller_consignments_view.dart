import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import '../../contracts/view/seller_contract_detail_view.dart';

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

    return Scaffold(
      appBar: SellerUi.appBar(context, "Consignments"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (val) => controller.search.value = val,
              decoration: InputDecoration(
                hintText: "Search contract, product, location...",
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
                  children: _filters.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: controller.workflowStatus.value == entry.key,
                              selectedColor: SellerUi.primary.withValues(alpha: 0.25),
                              onSelected: (_) => controller.setStatus(entry.key),
                            ),
                          ))
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
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.rows.length,
                        itemBuilder: (context, index) => _card(controller, controller.rows[index]),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _card(SellerConsignmentController controller, Map<String, dynamic> row) {
    final stage = row['status'] == 'received'
        ? 'received'
        : row['is_dispatched'] == true
            ? 'dispatched'
            : row['transporter_visible_at'] != null
                ? 'ready'
                : 'pending';
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => SellerContractDetailView(contractId: row['id'] as int))?.then((_) => controller.fetch()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text("Contract #${row['contract_id']}",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SellerUi.statusChip(stage),
                ],
              ),
              const SizedBox(height: 4),
              Text("${row['product_title'] ?? '-'} • Buyer ${row['display_buyer_id'] ?? '-'}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const Divider(height: 20),
              SellerUi.infoRow("Quantity", "${row['deal_quantity'] ?? '-'} ${row['quantity_unit'] ?? ''}"),
              SellerUi.infoRow("Trade Value", "₹${row['trade_value'] ?? '-'}"),
              SellerUi.infoRow("Route", "${row['loading_from'] ?? '-'} → ${row['loading_to'] ?? '-'}"),
              SellerUi.infoRow("Transporter", row['assigned_transporter']?.toString()),
              if (row['can_mark_ready'] == true) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.markReady(row),
                    icon: const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                    label: const Text("MARK READY FOR LOADING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SellerUi.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
