import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

/// Same content as the web "Contract Details" modal (summary, buyer and seller cards,
/// logistics route, remarks) plus the consignment workflow.
/// Data: `GET /api/mobile/contracts/{id}/` returns the web modal projection under "data".
class SellerContractDetailView extends StatefulWidget {
  final int contractId;
  const SellerContractDetailView({super.key, required this.contractId});

  @override
  State<SellerContractDetailView> createState() =>
      _SellerContractDetailViewState();
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
    if (mounted) setState(() => _loading = true);
    try {
      final response = await SellerServices.getContractDetails(
        widget.contractId,
      );
      _contract = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : Map<String, dynamic>.from(response);
    } catch (_) {
      // Fall back to the consignment row below when the contract call fails.
    }
    try {
      final response = await SellerServices.getConsignmentDetail(
        widget.contractId,
      );
      _consignment = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : null;
    } catch (_) {
      _consignment = null;
    }
    if (_contract == null && _consignment != null) _contract = _consignment;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markReady() async {
    final ok = await SellerUi.confirm(
      'Ready for Loading',
      'Mark this consignment ready? Transporters will be able to bid on it.',
      confirmText: 'Mark Ready',
    );
    if (!ok) return;
    final result = await SellerUi.run(
      () => SellerServices.consignmentAction(
        widget.contractId,
        'ready_for_loading',
      ),
    );
    if (result != null) await _load();
  }

  String _text(Object? value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String _money(Object? value, {Object? unit}) {
    final text = _text(value, '');
    if (text.isEmpty) return '-';
    final perUnit = _text(unit, '');
    return perUnit.isEmpty ? '₹$text' : '₹$text/$perUnit';
  }

  String _quantity(Map<String, dynamic> c) {
    final qty = _text(c['deal_quantity'], '');
    if (qty.isEmpty) return '-';
    return '$qty ${_text(c['quantity_unit'], '')}'.trim();
  }

  /// e.g. "Buyer2 tester (ID:113 | BUY817A619C67)" exactly as the web shows it.
  String _party(Map<String, dynamic> c, String prefix) =>
      _text(c['display_${prefix}_id'], _text(c['${prefix}_name']));

  Future<void> _open(String scheme, String value) async {
    final uri = Uri(scheme: scheme, path: value);
    if (!await launchUrl(uri)) SellerUi.error('Could not open $value');
  }

  Widget _summaryCard(BuildContext context, Map<String, dynamic> c) {
    final theme = Theme.of(context);
    final offerId = _text(c['product_id'], '');
    final offer = offerId.isEmpty
        ? _text(c['product_title'])
        : '${_text(c['product_title'])} (ID: $offerId)';
    return SellerUi.section(context, 'Contract ${_text(c['contract_id'], '#${c['id']}')}', [
      Row(
        children: [
          SellerUi.statusChip(_text(c['status'], 'active')),
          const Spacer(),
          Text('Total: ', style: theme.textTheme.bodyMedium),
          Text(
            _money(c['trade_value']),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: SellerUi.primary),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SellerUi.infoRow('Offer', offer),
      if (_text(c['product_category_name'], '').isNotEmpty)
        SellerUi.infoRow('Category', _text(c['product_category_name'])),
      if (_text(c['product_brand_name'], '').isNotEmpty)
        SellerUi.infoRow('Brand', _text(c['product_brand_name'])),
      SellerUi.infoRow('Quantity', _quantity(c)),
      if (c['bag_count'] != null)
        SellerUi.infoRow('Bags', '${c['bag_count']} × ${_text(c['packing_weight_kg'])} kg'),
      SellerUi.infoRow('Buyer', _party(c, 'buyer')),
      SellerUi.infoRow('Seller', _party(c, 'seller')),
      SellerUi.infoRow('Seller Quantity', _text(c['seller_quantity'])),
      const Divider(height: 22),
      SellerUi.infoRow('Deal Date', _text(c['deal_date'], SellerUi.date(c['confirmed_at']))),
      SellerUi.infoRow('Delivery Date', _text(c['delivery_date'])),
      SellerUi.infoRow('Pickup From', _text(c['loading_from_date'])),
      SellerUi.infoRow('Pickup To', _text(c['loading_to_date'])),
      SellerUi.infoRow('Buyer Offer Amount', _money(c['buyer_offer_amount'])),
      SellerUi.infoRow('Buyer Required Qty', _text(c['buyer_required_quantity'])),
      SellerUi.infoRow(
        'Deal Amount',
        _money(c['deal_amount'], unit: c['amount_unit']),
        valueColor: SellerUi.primary,
      ),
    ]);
  }

  Widget _partyCard(BuildContext context, Map<String, dynamic> c, {required bool seller}) {
    final theme = Theme.of(context);
    final prefix = seller ? 'seller' : 'buyer';
    final name = _text(c['${prefix}_name'], _text(c['${prefix}_username']));
    final realId = _text(c['${prefix}_real_id'] ?? c['${prefix}_id'], '');
    final mapId = _text(c['${prefix}_map_id'] ?? (seller ? c['seller_mapped_id'] : c['buyer_unique_id']), '');
    final idLine = [if (realId.isNotEmpty) 'ID: $realId', if (mapId.isNotEmpty) mapId].join(' | ');
    final company = _text(c['${prefix}_company_name'], '');
    final mobile = _text(c['${prefix}_mobile'], '');
    final email = _text(c['${prefix}_email'], '');

    Widget contact(IconData icon, String value, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(icon, size: 18, color: SellerUi.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
        );

    return SellerUi.section(context, seller ? 'Seller' : 'Buyer', [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: SellerUi.primary.withValues(alpha: .15),
            child: const Icon(Icons.person, color: SellerUi.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (idLine.isNotEmpty) Text(idLine, style: const TextStyle(color: Colors.brown, fontSize: 12)),
                if (company.isNotEmpty) Text('Company: $company', style: const TextStyle(color: Colors.brown, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (mobile.isNotEmpty) contact(Icons.phone, mobile, () => _open('tel', mobile)),
      if (email.isNotEmpty) contact(Icons.email_outlined, email, () => _open('mailto', email)),
      if (mobile.isEmpty && email.isEmpty)
        Text('Contact details are not available.', style: theme.textTheme.bodySmall),
    ]);
  }

  Widget _routeSection(BuildContext context, Map<String, dynamic> c) {
    Widget stop(IconData icon, String label, Object? value, Color color) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(_text(value), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        );

    return SellerUi.section(context, 'Logistics Route', [
      stop(Icons.radio_button_checked, 'Pickup location', c['loading_from'], Colors.green),
      Padding(
        padding: const EdgeInsets.only(left: 17),
        child: Row(children: [
          Container(width: 2, height: 30, color: Colors.grey.shade300),
          const SizedBox(width: 20),
          Icon(Icons.local_shipping_outlined, size: 18, color: Colors.grey.shade500),
        ]),
      ),
      stop(Icons.location_on, 'Delivery location', c['loading_to'], Colors.red),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contract;
    final consignment = _consignment;
    return Scaffold(
      appBar: SellerUi.appBar(context, 'Contract Details'),
      body: _loading && contract == null
          ? const Center(child: CircularProgressIndicator(color: SellerUi.primary))
          : contract == null
              ? const Center(child: Text('Contract not found'))
              : RefreshIndicator(
                  color: SellerUi.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _summaryCard(context, contract),
                      _partyCard(context, contract, seller: false),
                      _partyCard(context, contract, seller: true),
                      _routeSection(context, contract),
                      if (_text(contract['buyer_remark'], '').isNotEmpty ||
                          _text(contract['seller_remark'], '').isNotEmpty ||
                          _text(contract['admin_remark'], '').isNotEmpty)
                        SellerUi.section(context, 'Remarks', [
                          SellerUi.infoRow('Buyer', _text(contract['buyer_remark'])),
                          SellerUi.infoRow('Seller', _text(contract['seller_remark'])),
                          SellerUi.infoRow('Admin', _text(contract['admin_remark'])),
                        ]),
                      if (consignment != null) ...[
                        SellerUi.section(context, 'Consignment', [
                          SellerUi.infoRow('Ready for Loading', _text(consignment['ready_label'])),
                          SellerUi.infoRow('Transporter', _text(consignment['assigned_transporter'])),
                          SellerUi.infoRow('Dispatched', consignment['is_dispatched'] == true ? 'Yes' : 'No'),
                          SellerUi.infoRow('Received', _text(consignment['received_label'])),
                        ]),
                        if (consignment['can_mark_ready'] == true)
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _markReady,
                              icon: const Icon(Icons.local_shipping, color: Colors.white),
                              label: const Text(
                                'MARK READY FOR LOADING',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
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
