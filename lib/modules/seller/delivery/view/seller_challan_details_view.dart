import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/seller_delivery_controller.dart';

/// Full seller-facing delivery challan. The API returns the same snapshot-rich
/// document used by the web panel, so every available party, transport, charge
/// and audit value is presented here instead of being discarded by the UI.
class SellerChallanDetailsView extends StatefulWidget {
  const SellerChallanDetailsView({super.key, required this.challanId});

  final int challanId;

  @override
  State<SellerChallanDetailsView> createState() =>
      _SellerChallanDetailsViewState();
}

class _SellerChallanDetailsViewState extends State<SellerChallanDetailsView> {
  static const _primary = Color(0xFFFFB300);
  late final SellerDeliveryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SellerDeliveryController>()
        ? Get.find<SellerDeliveryController>()
        : Get.put(SellerDeliveryController());
    _controller.fetchChallanDetails(widget.challanId);
  }

  String _text(Object? value) {
    if (value == null) return '';
    if (value is Map) {
      for (final key in const [
        'name',
        'legal_name',
        'company_name',
        'username',
        'mobile',
        'id',
      ]) {
        final text = (value[key] ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }
    return value.toString().trim();
  }

  String _show(Object? value) {
    final text = _text(value);
    return text.isEmpty || text == 'null' ? '—' : text;
  }

  String _money(Object? value) {
    final text = _text(value);
    return text.isEmpty ? '—' : '₹$text';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Challan Details'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => _controller.fetchChallanDetails(widget.challanId),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: Obx(() {
      if (_controller.isDetailLoading.value) {
        return const Center(child: CircularProgressIndicator(color: _primary));
      }
      final data = _controller.selectedChallan.value;
      if (data == null) {
        return const Center(child: Text('Challan details were not found.'));
      }
      return _body(data);
    }),
  );

  Widget _body(Map<String, dynamic> data) {
    final status = _text(data['status']).toLowerCase();
    final items = (data['items'] is List ? data['items'] as List : const [])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
    final company = data['company'] is Map
        ? Map<String, dynamic>.from(data['company'] as Map)
        : const <String, dynamic>{};
    final responsible = data['created_by_display'] is Map
        ? Map<String, dynamic>.from(data['created_by_display'] as Map)
        : const <String, dynamic>{};
    final sellerCompany = data['seller_company'] is Map
        ? Map<String, dynamic>.from(data['seller_company'] as Map)
        : const <String, dynamic>{};
    final buyerCompany = data['buyer_company'] is Map
        ? Map<String, dynamic>.from(data['buyer_company'] as Map)
        : const <String, dynamic>{};
    final sellerInfo = data['seller'] is Map
        ? Map<String, dynamic>.from(data['seller'] as Map)
        : const <String, dynamic>{};
    final buyerInfo = data['buyer'] is Map
        ? Map<String, dynamic>.from(data['buyer'] as Map)
        : const <String, dynamic>{};
    final canDispatch = status == 'draft' || status == 'pending';

    return RefreshIndicator(
      onRefresh: () => _controller.fetchChallanDetails(widget.challanId),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _statusBanner(status),
          const SizedBox(height: 14),
          _section(
            icon: Icons.local_shipping_outlined,
            title: 'Challan Information',
            children: [
              _row(
                'Challan number',
                '#${_show(data['challan_number'] ?? data['id'])}',
              ),
              _row('Challan date', _show(data['challan_date'])),
              _row('Order / interest ID', _show(data['order'])),
              _row('Status', _show(data['status']).toUpperCase()),
              _row(
                'Total amount',
                _money(data['total_amount']),
                prominent: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.people_outline_rounded,
            title: 'Seller & Buyer',
            children: [
              _row(
                'Seller',
                _show(
                  data['seller_name_display'] ??
                      sellerCompany['company_name'] ??
                      sellerCompany['legal_name'] ??
                      sellerInfo['company_name'] ??
                      sellerInfo['name'] ??
                      data['seller_name'] ??
                      (data['seller'] is String ? data['seller'] : null),
                ),
              ),
              _row('Seller company', _show(data['seller_company_name'] ?? sellerCompany['legal_name'] ?? sellerCompany['company_name'])),
              _row('Seller GST', _show(data['seller_gst'] ?? sellerCompany['gst_number'] ?? sellerCompany['gst'] ?? sellerInfo['gst_number'] ?? sellerInfo['gst'])),
              _row('Seller PAN', _show(data['seller_pan'] ?? sellerCompany['pan_number'] ?? sellerCompany['pan'] ?? sellerInfo['pan_number'] ?? sellerInfo['pan'])),
              _row(
                'Seller address',
                _show(data['seller_address'] ?? sellerCompany['address_line_1'] ?? sellerCompany['address'] ?? sellerInfo['address_line_1'] ?? sellerInfo['address']),
                multiline: true,
              ),
              const Divider(height: 22),
              _row(
                'Buyer',
                _show(
                  data['buyer_name_display'] ??
                      buyerCompany['company_name'] ??
                      buyerCompany['legal_name'] ??
                      buyerInfo['company_name'] ??
                      buyerInfo['name'] ??
                      data['buyer_name'] ??
                      (data['buyer'] is String ? data['buyer'] : null),
                ),
              ),
              _row('Buyer company', _show(data['buyer_company_name'] ?? buyerCompany['legal_name'] ?? buyerCompany['company_name'])),
              _row('Buyer GST', _show(data['buyer_gst'] ?? buyerCompany['gst_number'] ?? buyerCompany['gst'] ?? buyerInfo['gst_number'] ?? buyerInfo['gst'])),
              _row('Buyer PAN', _show(data['buyer_pan'] ?? buyerCompany['pan_number'] ?? buyerCompany['pan'] ?? buyerInfo['pan_number'] ?? buyerInfo['pan'])),
              _row(
                'Buyer address',
                _show(data['buyer_address'] ?? buyerCompany['address_line_1'] ?? buyerCompany['address'] ?? buyerInfo['address_line_1'] ?? buyerInfo['address']),
                multiline: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.fire_truck_outlined,
            title: 'Transport Details',
            children: [
              _row(
                'Transporter',
                _show(data['transporter_name_display'] ?? data['transporter']),
              ),
              _row('Truck number', _show(data['truck_number'])),
              _row('Driver name', _show(data['driver_name'])),
              _row('Driver mobile', _show(data['driver_mobile'])),
              _row('Driver licence', _show(data['driver_license_number'])),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.currency_rupee_rounded,
            title: 'Charges & Settlement',
            children: [
              _row(
                'Lorry freight / bag',
                _money(data['lorry_freight_per_bag']),
              ),
              _row('Loading charges', _money(data['loading_charges'])),
              _row('Other expenses', _money(data['other_exp'])),
              _row('Less advance', _money(data['less_advance'])),
              _row('Item total', _money(data['total_amount']), prominent: true),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.business_outlined,
            title: 'Company & Responsibility',
            children: [
              _row(
                'Company',
                _show(
                  company['legal_name'] ??
                      company['company_name'] ??
                      data['company_name'],
                ),
              ),
              _row(
                'Company GST',
                _show(company['gst_number'] ?? company['gst']),
              ),
              _row(
                'Company address',
                _show(company['address'] ?? company['address_line_1']),
                multiline: true,
              ),
              _row(
                'Created / managed by',
                _show(
                  responsible['name'] ??
                      data['created_by_name'] ??
                      data['created_by'],
                ),
              ),
              _row('Responsible mobile', _show(responsible['mobile'])),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.inventory_2_outlined,
            title: 'Product Items (${items.length})',
            children: items.isEmpty
                ? const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('No item lines available.'),
                    ),
                  ]
                : items.map(_itemCard).toList(),
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.history_rounded,
            title: 'Timeline',
            children: [
              _row('Created at', _show(data['created_at'])),
              _row('Last updated', _show(data['updated_at'])),
              _row('Dispatched at', _show(data['dispatched_at'])),
              _row(
                'Dispatched by',
                _show(data['dispatched_by_name'] ?? data['dispatched_by']),
              ),
              _row('Received at', _show(data['received_at'])),
              _row(
                'Received by',
                _show(data['received_by_name'] ?? data['received_by']),
              ),
            ],
          ),
          if (_text(data['narration']).isNotEmpty) ...[
            const SizedBox(height: 12),
            _section(
              icon: Icons.notes_rounded,
              title: 'Narration',
              children: [Text(_text(data['narration']))],
            ),
          ],
          if (canDispatch) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _controller.dispatchChallan(widget.challanId),
                icon: const Icon(Icons.send_rounded),
                label: const Text('DISPATCH SHIPMENT'),
                style: FilledButton.styleFrom(backgroundColor: _primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    final (color, label) = switch (status) {
      'dispatched' => (Colors.blue, 'DISPATCHED'),
      'received' || 'delivered' => (Colors.green, 'DELIVERED'),
      'cancelled' => (Colors.red, 'CANCELLED'),
      _ => (Colors.orange, status.isEmpty ? 'DRAFT' : status.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 10),
          Text(
            'Current status: $label',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    ),
  );

  Widget _row(
    String label,
    String value, {
    bool prominent = false,
    bool multiline = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: multiline ? null : 2,
          overflow: multiline ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: prominent ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _itemCard(Map<String, dynamic> item) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: _primary.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _show(item['product_name']),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _itemRow(
          'Quantity',
          '${_show(item['quantity'])} ${_show(item['unit'])}',
        ),
        _itemRow(
          'Bags / packing',
          '${_show(item['bag_count'])} / ${_show(item['packing_weight_kg'])} KG',
        ),
        _itemRow('Rate', _money(item['rate'])),
        _itemRow(
          'Commission',
          '${_show(item['commission_type'])} • ${_show(item['brokerage_rate'])}',
        ),
        const Divider(height: 18),
        _itemRow('Item total', _money(item['amount']), bold: true),
      ],
    ),
  );

  Widget _itemRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
