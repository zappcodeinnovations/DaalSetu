import 'package:flutter/material.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:daalsetu/theme/app_theme.dart';

/// One stock movement from `/api/offers/<id>/stock-history/`, shaped for the cards below.
Map<String, dynamic> _stockRow(Map<String, dynamic> row) {
  String text(dynamic v) => v == null || v.toString() == 'null' ? '' : v.toString();
  final unit = text(row['quantity_unit']).toUpperCase();
  final change = text(row['quantity_change_display']).isNotEmpty
      ? text(row['quantity_change_display'])
      : '${text(row['quantity_change'])} $unit'.trim();
  final bags = row['updated_bag_count'] ?? row['previous_bag_count'];
  final performer = row['performed_by'];
  return {
    'actionType': text(row['action_label']).isNotEmpty
        ? text(row['action_label'])
        : text(row['action_type']),
    'bags': text(bags).isEmpty ? '-' : text(bags),
    'packingKg': text(row['packing_weight_kg']).isEmpty ? '-' : text(row['packing_weight_kg']),
    'quantityChange': change,
    'previousStock': '${text(row['previous_stock'])} $unit'.trim(),
    'updatedStock': '${text(row['updated_stock'])} $unit'.trim(),
    'dateTime': text(row['created_at_display']).isNotEmpty
        ? text(row['created_at_display'])
        : text(row['created_at']),
    'performedBy': text(performer is Map ? performer['name'] : performer),
  };
}

/// Loads the real stock history of an offer (the same API the seller screen uses).
Future<List<Map<String, dynamic>>> loadStockHistory(String productId) async {
  final id = int.tryParse(productId);
  if (id == null) return [];
  final data = await SellerServices.getOfferStockHistory(id);
  return (data['results'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => _stockRow(Map<String, dynamic>.from(e)))
      .toList();
}

class StockHistoryDialog extends StatefulWidget {
  final String productId;
  final String productTitle;
  final String sellerName;
  final String currentStock;

  const StockHistoryDialog({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.sellerName,
    required this.currentStock,
  });

  @override
  State<StockHistoryDialog> createState() => _StockHistoryDialogState();
}

class _StockHistoryDialogState extends State<StockHistoryDialog> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await loadStockHistory(widget.productId);
      if (!mounted) return;
      setState(() => _history = rows);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock History',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _loading ? 'Loading...' : '${_history.length} record(s)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  // Product details as plain label / value rows: long names wrap inside their own row.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Product', widget.productTitle),
                        _infoRow('Seller', widget.sellerName),
                        _infoRow('Current Stock', widget.currentStock),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (_history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No stock movements yet.')),
                    )
                  else
                    for (final record in _history) StockHistoryRecordCard(record: record),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockHistoryFullScreen(
                              productId: widget.productId,
                              productTitle: widget.productTitle,
                              sellerName: widget.sellerName,
                              currentStock: widget.currentStock,
                              history: _history,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text(
                        'Open Full Page',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One stock movement as a card (shared by the dialog and the full page).
class StockHistoryRecordCard extends StatelessWidget {
  const StockHistoryRecordCard({super.key, required this.record});

  final Map<String, dynamic> record;

  Widget _detailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      record['actionType']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  record['dateTime']?.toString() ?? '',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _detailItem('Quantity Change', record['quantityChange']?.toString() ?? '')),
                Expanded(
                  child: _detailItem('Bags / Packing', '${record['bags']} / ${record['packingKg']} kg'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _detailItem('Previous Stock', record['previousStock']?.toString() ?? '')),
                Expanded(child: _detailItem('Updated Stock', record['updatedStock']?.toString() ?? '')),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Performed by: ${record['performedBy'] ?? ''}',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class StockHistoryFullScreen extends StatelessWidget {
  final String productId;
  final String productTitle;
  final String sellerName;
  final String currentStock;
  final List<Map<String, dynamic>> history;

  const StockHistoryFullScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.sellerName,
    required this.currentStock,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock History: $productTitle',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 20, color: AppTheme.primaryGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          productTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text('Seller: $sellerName', style: TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text('Current Stock: $currentStock', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction Records (${history.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No stock movements yet.')),
            )
          else
            for (final record in history) StockHistoryRecordCard(record: record),
        ],
      ),
    );
  }
}
