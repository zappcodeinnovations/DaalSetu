import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Stock History",
        subtitle: "Inventory movement & bag ledger",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => _load(reset: true),
        ),
      ),
      body: RefreshIndicator(
        color: SellerUi.primary,
        onRefresh: () => _load(reset: true),
        child: _loading && _rows.isEmpty
            ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: SellerUi.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          SellerUi.infoRow(
                            "Current Stock",
                            product == null ? null : "${product['current_stock']} ${product['quantity_unit'] ?? ''}",
                          ),
                          SellerUi.infoRow("Remaining Bags", product?['remaining_bag_count']?.toString()),
                          SellerUi.infoRow(
                            "Packing Weight",
                            product?['packing_weight_kg'] == null ? null : "${product!['packing_weight_kg']} kg",
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text("No stock changes recorded yet", style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                      ),
                    ),
                  ..._rows.map(_historyCard),
                  if (_hasNext)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: _loading
                              ? null
                              : () {
                                  _page += 1;
                                  _load();
                                },
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text("Load More Logs", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> row) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final change = row['quantity_change_display']?.toString() ?? row['quantity_change']?.toString() ?? '';
    final isIncrease = !change.trim().startsWith('-');
    final badgeColor = isIncrease ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncrease ? IconlyLight.arrow_up : IconlyLight.arrow_down,
                    color: badgeColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row['action_label']?.toString() ?? row['action_type']?.toString() ?? '-',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
