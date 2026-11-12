import 'package:flutter/material.dart';
import '../../../../utils/money_format.dart';
import 'package:get/get.dart';

import '../controller/seller_delivery_controller.dart';
import 'package:daalsetu/widgets/app_shell.dart';

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

  String _firstNonEmpty(List<dynamic> candidates) {
    for (final item in candidates) {
      if (item == null) continue;
      if (item is Map) {
        final mapText = _text(item);
        if (mapText.isNotEmpty && mapText != 'null') return mapText;
        continue;
      }
      final text = item.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  String _show(Object? value) {
    final text = _text(value);
    return text.isEmpty || text == 'null' ? '—' : text;
  }

  String _money(Object? value) {
    final text = _text(value);
    return text.isEmpty || text == 'null' ? '—' : formatInr(text);
  }

  String _formatDate(Object? value) {
    if (value == null) return '—';
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null') return '—';
    try {
      final dt = DateTime.parse(str);
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      return '$day-$month-$year';
    } catch (_) {
      return str;
    }
  }

  String _formatDateTime(Object? value) {
    if (value == null) return '—';
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null') return '—';
    try {
      final dt = DateTime.parse(str).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year.toString();
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final hour = hour12.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day-$month-$year $hour:$minute $period';
    } catch (_) {
      return str;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
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

  Widget _body(Map<String, dynamic> rawData) {
    final data = rawData['data'] is Map
        ? Map<String, dynamic>.from(rawData['data'] as Map)
        : rawData;

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
    final transporterInfo = data['transporter'] is Map
        ? Map<String, dynamic>.from(data['transporter'] as Map)
        : const <String, dynamic>{};
    final canDispatch = status == 'draft' || status == 'pending';

    final createdByName = _firstNonEmpty([
      data['created_by_name'],
      responsible['name'],
      data['display_responsible_name'],
      (data['display_responsible_snapshot'] is Map
          ? data['display_responsible_snapshot']['name']
          : null),
      (data['created_by_display'] is Map
          ? data['created_by_display']['name']
          : null),
      (data['created_by'] is Map
          ? (data['created_by']['full_name'] ?? data['created_by']['name'])
          : null),
      (data['created_by'] is String &&
              int.tryParse(data['created_by'].toString()) == null
          ? data['created_by']
          : null),
    ]);

    final sellerName = _firstNonEmpty([
      data['seller_name_display'],
      data['seller_name'],
      sellerInfo['full_name'],
      sellerInfo['name'],
      sellerCompany['legal_name'],
      sellerCompany['company_name'],
      sellerCompany['name'],
      (data['seller'] is String &&
              int.tryParse(data['seller'].toString()) == null
          ? data['seller']
          : null),
    ]);
    final sellerCompanyName = _firstNonEmpty([
      data['seller_company_name'],
      sellerCompany['legal_name'],
      sellerCompany['company_name'],
      sellerInfo['company_name'],
    ]);
    final sellerGst = _firstNonEmpty([
      data['seller_gst'],
      sellerCompany['gst_number'],
      sellerCompany['gst'],
      sellerInfo['gst_number'],
      sellerInfo['gst'],
    ]);
    final sellerPan = _firstNonEmpty([
      data['seller_pan'],
      sellerCompany['pan_number'],
      sellerCompany['pan'],
      sellerInfo['pan_number'],
      sellerInfo['pan'],
    ]);
    final sellerAddress = _firstNonEmpty([
      data['seller_address'],
      sellerCompany['address_display'],
      sellerCompany['address'],
      sellerCompany['address_line_1'],
      sellerInfo['address'],
      sellerInfo['address_line_1'],
    ]);

    final buyerName = _firstNonEmpty([
      data['buyer_name_display'],
      data['buyer_name'],
      buyerInfo['full_name'],
      buyerInfo['name'],
      buyerCompany['legal_name'],
      buyerCompany['company_name'],
      buyerCompany['name'],
      (data['buyer'] is String &&
              int.tryParse(data['buyer'].toString()) == null
          ? data['buyer']
          : null),
    ]);
    final buyerCompanyName = _firstNonEmpty([
      data['buyer_company_name'],
      buyerCompany['legal_name'],
      buyerCompany['company_name'],
      buyerInfo['company_name'],
    ]);
    final buyerGst = _firstNonEmpty([
      data['buyer_gst'],
      buyerCompany['gst_number'],
      buyerCompany['gst'],
      buyerInfo['gst_number'],
      buyerInfo['gst'],
    ]);
    final buyerPan = _firstNonEmpty([
      data['buyer_pan'],
      buyerCompany['pan_number'],
      buyerCompany['pan'],
      buyerInfo['pan_number'],
      buyerInfo['pan'],
    ]);
    final buyerAddress = _firstNonEmpty([
      data['buyer_address'],
      buyerCompany['address_display'],
      buyerCompany['address'],
      buyerCompany['address_line_1'],
      buyerInfo['address'],
      buyerInfo['address_line_1'],
    ]);

    final transporterName = _firstNonEmpty([
      data['transporter_name_display'],
      data['transporter_name'],
      transporterInfo['full_name'],
      transporterInfo['name'],
      transporterInfo['company_name'],
      (data['transporter'] is String &&
              int.tryParse(data['transporter'].toString()) == null
          ? data['transporter']
          : null),
    ]);
    final truckNumber = _firstNonEmpty([
      data['truck_number'],
      data['vehicle_number'],
    ]);
    final driverName = _firstNonEmpty([
      data['driver_name'],
      (data['driver'] is Map ? data['driver']['name'] : null),
    ]);
    final driverMobile = _firstNonEmpty([
      data['driver_mobile'],
      data['driver_phone'],
      (data['driver'] is Map ? data['driver']['mobile'] : null),
    ]);
    final driverLicense = _firstNonEmpty([
      data['driver_license_number'],
      data['license_number'],
      data['driver_licence'],
    ]);

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
              _row('Challan date', _formatDate(data['challan_date'])),
              if (_text(data['order']).isNotEmpty)
                _row('Order / interest ID', _show(data['order'])),
              _row('Status', _show(data['status_display'] ?? data['status']).toUpperCase()),
              _row(
                'Total amount',
                _money(data['total_amount']),
                prominent: true,
              ),
              _row('Created by', _show(createdByName)),
              _row('Created at', _formatDateTime(data['created_at'])),
              _row('Updated at', _formatDateTime(data['updated_at'])),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.storefront_outlined,
            title: 'Seller Information',
            children: [
              _row('Name', _show(sellerName)),
              _row('Company', _show(sellerCompanyName)),
              _row('GST Number', _show(sellerGst)),
              _row('PAN Number', _show(sellerPan)),
              _row('Address', _show(sellerAddress)),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.person_outline_rounded,
            title: 'Buyer Information',
            children: [
              _row('Name', _show(buyerName)),
              _row('Company', _show(buyerCompanyName)),
              _row('GST Number', _show(buyerGst)),
              _row('PAN Number', _show(buyerPan)),
              _row('Address', _show(buyerAddress)),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.fire_truck_outlined,
            title: 'Transport Details',
            children: [
              _row('Truck number', _show(truckNumber)),
              _row('Driver name', _show(driverName)),
              _row('License number', _show(driverLicense)),
              _row('Mobile', _show(driverMobile)),
              _row('Transporter', _show(transporterName)),
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
              _row('Created at', _formatDateTime(data['created_at'])),
              _row('Last updated', _formatDateTime(data['updated_at'])),
              _row('Dispatched at', _formatDateTime(data['dispatched_at'])),
              _row(
                'Dispatched by',
                _show(data['dispatched_by_name'] ?? data['dispatched_by']),
              ),
              _row('Received at', _formatDateTime(data['received_at'])),
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
    bool multiline = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          softWrap: true,
          style: TextStyle(
            fontSize: prominent ? 16 : 14,
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
          softWrap: true,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            softWrap: true,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
