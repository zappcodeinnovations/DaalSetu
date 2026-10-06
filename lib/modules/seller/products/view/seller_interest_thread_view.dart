import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

/// Full negotiation history of one buyer interest (GET /api/offers/<id>/interests/<id>/).
class SellerInterestThreadView extends StatefulWidget {
  final int productId;
  final int interestId;
  const SellerInterestThreadView({super.key, required this.productId, required this.interestId});

  @override
  State<SellerInterestThreadView> createState() => _SellerInterestThreadViewState();
}

class _SellerInterestThreadViewState extends State<SellerInterestThreadView> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await SellerServices.getOfferInterestThread(widget.productId, widget.interestId);
      _data = response['data'] is Map<String, dynamic> ? response['data'] : null;
    } catch (e) {
      SellerUi.error(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _counter() async {
    final price = TextEditingController();
    final quantity = TextEditingController(text: '${_data?['required_quantity'] ?? ''}');
    InputDecoration deco(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder());
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Counter Offer", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Counter Price")),
          const SizedBox(height: 10),
          TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: deco("Counter Quantity")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SellerUi.primary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("SEND", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await SellerUi.run(() => SellerServices.sendCounterOfferMessage(
          widget.productId,
          widget.interestId,
          counterPrice: price.text.trim(),
          counterQuantity: quantity.text.trim(),
        ));
    if (result != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final rows = (data?['messages'] as List? ?? []).whereType<Map>().toList();
    return Scaffold(
      appBar: SellerUi.appBar(context, "Negotiation"),
      floatingActionButton: data != null && data['can_seller_action'] == true && data['is_read_only'] != true
          ? FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: SellerUi.primary,
              onPressed: _counter,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              label: const Text("COUNTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: _loading && data == null
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : data == null
              ? const Center(child: Text("Negotiation not found"))
              : RefreshIndicator(
                  color: SellerUi.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      SellerUi.section(context, data['product_title']?.toString() ?? 'Offer', [
                        Align(alignment: Alignment.centerLeft, child: SellerUi.statusChip('${data['status']}')),
                        const SizedBox(height: 8),
                        SellerUi.infoRow("Buyer", data['buyer_display_id']?.toString()),
                        SellerUi.infoRow("Buyer Price", "₹${data['offered_amount'] ?? '-'}", valueColor: SellerUi.primary),
                        SellerUi.infoRow("Quantity", data['required_quantity']?.toString()),
                        if (data['required_bag_count'] != null)
                          SellerUi.infoRow("Bags", "${data['required_bag_count']} × ${data['packing_weight_kg'] ?? '-'} kg"),
                        SellerUi.infoRow("Buyer Remark", data['buyer_remark']?.toString()),
                      ]),
                      if (rows.isEmpty)
                        Center(child: Text("No negotiation yet.", style: TextStyle(color: Colors.grey.shade600))),
                      ...rows.map((row) => _bubble(context, row)),
                    ],
                  ),
                ),
    );
  }

  Widget _bubble(BuildContext context, Map row) {
    final role = '${row['actor_role'] ?? ''}';
    final mine = role == 'seller';
    String present(dynamic v) => (v == null || '$v'.isEmpty || '$v' == 'null') ? '' : '$v';
    final price = present(row['counter_price']);
    final quantity = present(row['counter_quantity']);
    final bags = present(row['counter_bag_count']);
    final statusChange = present(row['to_status']);
    final lines = <String>[
      if (price.isNotEmpty) "Price: ₹$price ${present(row['price_unit'])}",
      if (quantity.isNotEmpty) "Quantity: $quantity ${present(row['quantity_unit'])}",
      if (bags.isNotEmpty) "Bags: $bags × ${present(row['counter_packing_weight_kg'])} kg",
      if (statusChange.isNotEmpty) "Status → ${statusChange.replaceAll('_', ' ')}",
      if (present(row['message']).isNotEmpty) present(row['message']),
    ];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (mine ? SellerUi.primary : Colors.blueGrey).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${mine ? 'You' : (role.isEmpty ? 'System' : role[0].toUpperCase() + role.substring(1))} • ${present(row['action']).replaceAll('_', ' ')}",
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            ...lines.map((l) => Text(l, style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 2),
            Text(SellerUi.date(row['timestamp']), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
