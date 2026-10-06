import 'package:flutter/material.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

/// Contract details plus its consignment workflow (ready for loading / dispatch / received).
class SellerContractDetailView extends StatefulWidget {
  final int contractId;
  const SellerContractDetailView({super.key, required this.contractId});

  @override
  State<SellerContractDetailView> createState() => _SellerContractDetailViewState();
}

class _SellerContractDetailViewState extends State<SellerContractDetailView> {
  Map<String, dynamic>? _contract;
  Map<String, dynamic>? _consignment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await SellerServices.getContractDetails(widget.contractId);
      _contract = response['data'] is Map<String, dynamic> ? response['data'] : response;
    } catch (e) {
      SellerUi.error(e);
    }
    try {
      // Only active / received contracts have a consignment workflow.
      final response = await SellerServices.getConsignmentDetail(widget.contractId);
      _consignment = response['data'] is Map<String, dynamic> ? response['data'] : null;
    } catch (_) {
      _consignment = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markReady() async {
    final ok = await SellerUi.confirm(
      "Ready for Loading",
      "Mark this consignment ready? Transporters will be able to bid on it.",
      confirmText: "Mark Ready",
    );
    if (!ok) return;
    final result = await SellerUi.run(() => SellerServices.consignmentAction(widget.contractId, 'ready_for_loading'));
    if (result != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _contract;
    final cons = _consignment;
    return Scaffold(
      appBar: SellerUi.appBar(context, "Contract Details"),
      body: _loading && c == null
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : c == null
              ? const Center(child: Text("Contract not found"))
              : RefreshIndicator(
                  color: SellerUi.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SellerUi.section(context, "Contract #${c['contract_id'] ?? c['id']}", [
                        Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip('${c['status'] ?? 'active'}')),
                        const SizedBox(height: 8),
                        SellerUi.infoRow("Product", c['product_title']?.toString()),
                        SellerUi.infoRow("Category", c['product_category_name']?.toString()),
                        SellerUi.infoRow("Buyer", (c['display_buyer_id'] ?? c['buyer_name'])?.toString()),
                        SellerUi.infoRow("Deal Price", "₹${c['deal_amount'] ?? '-'} / ${c['amount_unit'] ?? ''}", valueColor: SellerUi.primary),
                        SellerUi.infoRow("Quantity", "${c['deal_quantity'] ?? '-'} ${c['quantity_unit'] ?? ''}"),
                        if (c['bag_count'] != null)
                          SellerUi.infoRow("Bags", "${c['bag_count']} × ${c['packing_weight_kg'] ?? '-'} kg"),
                        SellerUi.infoRow("Loading From", c['loading_from']?.toString()),
                        SellerUi.infoRow("Loading To", c['loading_to']?.toString()),
                        SellerUi.infoRow("Confirmed At", SellerUi.date(c['confirmed_at'])),
                      ]),
                      if ((c['buyer_remark'] ?? '').toString().isNotEmpty || (c['seller_remark'] ?? '').toString().isNotEmpty)
                        SellerUi.section(context, "Remarks", [
                          SellerUi.infoRow("Buyer", c['buyer_remark']?.toString()),
                          SellerUi.infoRow("Seller", c['seller_remark']?.toString()),
                          SellerUi.infoRow("Admin", c['admin_remark']?.toString()),
                        ]),
                      if (cons != null) ...[
                        SellerUi.section(context, "Consignment", [
                          SellerUi.infoRow("Ready for Loading", cons['ready_label']?.toString()),
                          SellerUi.infoRow("Transporter", cons['assigned_transporter']?.toString()),
                          SellerUi.infoRow("Dispatched", cons['is_dispatched'] == true ? "Yes" : "No"),
                          SellerUi.infoRow("Received", cons['received_label']?.toString()),
                        ]),
                        if (cons['can_mark_ready'] == true)
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _markReady,
                              icon: const Icon(Icons.local_shipping, color: Colors.white),
                              label: const Text("MARK READY FOR LOADING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SellerUi.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
