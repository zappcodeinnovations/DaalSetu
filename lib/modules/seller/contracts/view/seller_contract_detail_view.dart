import 'package:flutter/material.dart';

import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';

/// Web-parity contract details plus the consignment workflow.
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
    } catch (error) {
      SellerUi.error(error);
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
    return text.isEmpty ? fallback : text;
  }

  Widget _partySection(
    BuildContext context,
    Map<String, dynamic> contract, {
    required bool seller,
  }) {
    final prefix = seller ? 'seller' : 'buyer';
    return SellerUi.section(
      context,
      seller ? 'Seller Details' : 'Buyer Details',
      [
        SellerUi.infoRow(
          'Name',
          _text(contract['${prefix}_name'] ?? contract['${prefix}_username']),
        ),
        SellerUi.infoRow('Company', _text(contract['${prefix}_company_name'])),
        SellerUi.infoRow('Display ID', _text(contract['display_${prefix}_id'])),
        SellerUi.infoRow('Mobile', _text(contract['${prefix}_mobile'])),
        SellerUi.infoRow('Email', _text(contract['${prefix}_email'])),
      ],
    );
  }

  Widget _routeSection(BuildContext context, Map<String, dynamic> contract) {
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
              Text(
                _text(value),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );

    return SellerUi.section(context, 'Pickup & Delivery', [
      stop(
        Icons.radio_button_checked,
        'Pickup location',
        contract['loading_from'],
        Colors.green,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 17),
        child: Container(width: 2, height: 24, color: Colors.grey.shade300),
      ),
      stop(
        Icons.location_on,
        'Delivery location',
        contract['loading_to'],
        Colors.red,
      ),
      const SizedBox(height: 12),
      SellerUi.infoRow(
        'Loading from date',
        _text(contract['loading_from_date']),
      ),
      SellerUi.infoRow('Loading to date', _text(contract['loading_to_date'])),
      SellerUi.infoRow('Expected delivery', _text(contract['delivery_date'])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final contract = _contract;
    final consignment = _consignment;
    return Scaffold(
      appBar: SellerUi.appBar(context, 'Contract Details'),
      body: _loading && contract == null
          ? const Center(
              child: CircularProgressIndicator(color: SellerUi.primary),
            )
          : contract == null
          ? const Center(child: Text('Contract not found'))
          : RefreshIndicator(
              color: SellerUi.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SellerUi.section(
                    context,
                    'Contract #${contract['contract_id'] ?? contract['id']}',
                    [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SellerUi.statusChip(
                          '${contract['status'] ?? 'active'}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SellerUi.infoRow(
                        'Product',
                        _text(contract['product_title']),
                      ),
                      SellerUi.infoRow(
                        'Category',
                        _text(contract['product_category_name']),
                      ),
                      SellerUi.infoRow(
                        'Brand',
                        _text(contract['product_brand_name']),
                      ),
                      SellerUi.infoRow(
                        'Deal Price',
                        '₹${contract['deal_amount'] ?? '-'} / ${contract['amount_unit'] ?? ''}',
                        valueColor: SellerUi.primary,
                      ),
                      SellerUi.infoRow(
                        'Quantity',
                        '${contract['deal_quantity'] ?? '-'} ${contract['quantity_unit'] ?? ''}',
                      ),
                      if (contract['bag_count'] != null)
                        SellerUi.infoRow(
                          'Packing',
                          '${contract['bag_count']} × ${contract['packing_weight_kg'] ?? '-'} kg',
                        ),
                      SellerUi.infoRow(
                        'Trade Value',
                        '₹${contract['trade_value'] ?? '-'}',
                        valueColor: SellerUi.primary,
                      ),
                      SellerUi.infoRow(
                        'Buyer Offer',
                        _text(contract['buyer_offer_amount']) == '-'
                            ? '-'
                            : '₹${contract['buyer_offer_amount']}',
                      ),
                      SellerUi.infoRow(
                        'Buyer Required Qty',
                        _text(contract['buyer_required_quantity']),
                      ),
                      SellerUi.infoRow(
                        'Confirmed At',
                        SellerUi.date(contract['confirmed_at']),
                      ),
                    ],
                  ),
                  _partySection(context, contract, seller: false),
                  _partySection(context, contract, seller: true),
                  _routeSection(context, contract),
                  if (_text(contract['buyer_remark'], '').isNotEmpty ||
                      _text(contract['seller_remark'], '').isNotEmpty ||
                      _text(contract['admin_remark'], '').isNotEmpty)
                    SellerUi.section(context, 'Remarks', [
                      SellerUi.infoRow(
                        'Buyer',
                        _text(contract['buyer_remark']),
                      ),
                      SellerUi.infoRow(
                        'Seller',
                        _text(contract['seller_remark']),
                      ),
                      SellerUi.infoRow(
                        'Admin',
                        _text(contract['admin_remark']),
                      ),
                    ]),
                  if (consignment != null) ...[
                    SellerUi.section(context, 'Consignment', [
                      SellerUi.infoRow(
                        'Ready for Loading',
                        _text(consignment['ready_label']),
                      ),
                      SellerUi.infoRow(
                        'Transporter',
                        _text(consignment['assigned_transporter']),
                      ),
                      SellerUi.infoRow(
                        'Dispatched',
                        consignment['is_dispatched'] == true ? 'Yes' : 'No',
                      ),
                      SellerUi.infoRow(
                        'Received',
                        _text(consignment['received_label']),
                      ),
                    ]),
                    if (consignment['can_mark_ready'] == true)
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _markReady,
                          icon: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'MARK READY FOR LOADING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SellerUi.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
