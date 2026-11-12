import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

class OfferStockHistoryView extends StatefulWidget {
  final int productId;
  final String title;
  const OfferStockHistoryView({super.key, required this.productId, required this.title});

  @override
  State<OfferStockHistoryView> createState() => _OfferStockHistoryViewState();
}

class _OfferStockHistoryViewState extends State<OfferStockHistoryView> {
  final List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic>? _product;
  int _page = 1;
  bool _hasNext = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() => _loading = true);
    try {
      final data = await SellerServices.getOfferStockHistory(widget.productId, page: _page);
      final results = (data['results'] as List? ?? []).whereType<Map<String, dynamic>>();
      setState(() {
        if (reset) _rows.clear();
        _rows.addAll(results);
        _product = data['product'] is Map<String, dynamic> ? data['product'] : _product;
        _hasNext = data['pagination']?['has_next'] == true;
      });
    } catch (e) {
      SellerUi.error(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      appBar: SellerUi.appBar(context, "Stock History"),
      body: RefreshIndicator(
        color: SellerUi.primary,
        onRefresh: () => _load(reset: true),
        child: _loading && _rows.isEmpty
            ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SellerUi.section(context, widget.title, [
                    SellerUi.infoRow("Current Stock", product == null ? null : "${product['current_stock']} ${product['quantity_unit'] ?? ''}"),
                    SellerUi.infoRow("Remaining Bags", product?['remaining_bag_count']?.toString()),
                    SellerUi.infoRow("Packing Weight", product?['packing_weight_kg'] == null ? null : "${product!['packing_weight_kg']} kg"),
                  ]),
                  if (_rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(child: Text("No stock changes yet", style: GoogleFonts.poppins(color: Colors.grey.shade600))),
                    ),
                  ..._rows.map(_historyCard),
                  if (_hasNext)
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              _page += 1;
                              _load();
                            },
                      child: const Text("Load more"),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> row) {
    final change = row['quantity_change_display']?.toString() ?? row['quantity_change']?.toString() ?? '';
    final isIncrease = !change.trim().startsWith('-');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isIncrease ? IconlyLight.arrow_up : IconlyLight.arrow_down, color: isIncrease ? Colors.green : Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(row['action_label']?.toString() ?? row['action_type']?.toString() ?? '-',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text(change, style: TextStyle(fontWeight: FontWeight.bold, color: isIncrease ? Colors.green : Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            SellerUi.infoRow("Stock", "${row['previous_stock']} → ${row['updated_stock']} ${row['quantity_unit'] ?? ''}"),
            if (row['previous_bag_count'] != null || row['updated_bag_count'] != null)
              SellerUi.infoRow("Bags", "${row['previous_bag_count'] ?? '-'} → ${row['updated_bag_count'] ?? '-'}"),
            SellerUi.infoRow("By", row['performed_by']?['name']?.toString()),
            SellerUi.infoRow("When", row['created_at_display']?.toString() ?? SellerUi.date(row['created_at'])),
          ],
        ),
      ),
    );
  }
}
