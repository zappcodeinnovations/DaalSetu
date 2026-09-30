
import 'package:flutter/material.dart';
import 'package:agro_broker/theme/app_theme.dart';

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
  // Mock data since API endpoint for Stock History wasn't explicitly provided
  final List<Map<String, dynamic>> mockHistory = [
    {
      'actionType': 'Stock Added',
      'bags': 400,
      'packingKg': '30.000',
      'quantityChange': '+120.000 QTL',
      'previousStock': '0.000 QTL',
      'updatedStock': '120.000 QTL',
      'dateTime': '28-07-2026 07:26 PM',
      'performedBy': 'MUKESH',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Stock History",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("${mockHistory.length} record(s)", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Product Info Box
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Product: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: widget.productTitle),
                          ]
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: "Seller: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: widget.sellerName),
                          ]
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: "Current Stock: ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: widget.currentStock),
                            ]
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Columns Button Placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.view_column, size: 16),
                  label: const Text("Columns"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Data Table
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Theme.of(context).cardColor),
                        columns: [
                          DataColumn(label: Text('ACTION TYPE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('BAGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('PACKING KG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('QUANTITY CHANGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('PREVIOUS STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('UPDATED STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('DATE & TIME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                          DataColumn(label: Text('PERFORMED BY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMuted))),
                        ],
                        rows: mockHistory.map((h) => DataRow(
                          cells: [
                            DataCell(Text(h['actionType'].toString())),
                            DataCell(Text(h['bags'].toString())),
                            DataCell(Text(h['packingKg'].toString())),
                            DataCell(Text(h['quantityChange'].toString())),
                            DataCell(Text(h['previousStock'].toString())),
                            DataCell(Text(h['updatedStock'].toString())),
                            DataCell(Text(h['dateTime'].toString())),
                            DataCell(Text(h['performedBy'].toString())),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),
            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                    child: const Text("Open Full Page", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
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
