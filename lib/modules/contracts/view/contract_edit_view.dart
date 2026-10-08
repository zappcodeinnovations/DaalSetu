import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Web "Edit Contract" modal: deal values, locations, dates, remarks and status.
/// Only changed fields are sent, so a closed contract can still get a status/remark update.
class ContractEditView extends StatefulWidget {
  const ContractEditView({super.key, required this.contract});

  final ContractDetailModel contract;

  @override
  State<ContractEditView> createState() => _ContractEditViewState();
}

class _ContractEditViewState extends State<ContractEditView> {
  static const _statuses = {'active': 'Active', 'received': 'Received', 'completed': 'Completed', 'cancelled': 'Cancelled'};

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text;
  late final Map<String, String> _original;
  late String _status;
  final _dates = <String, DateTime?>{'loading_from_date': null, 'loading_to_date': null, 'delivery_date': null};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    _original = {
      'deal_amount': c.dealAmount,
      'deal_quantity': c.dealQuantity,
      'bag_count': c.bagCount?.toString() ?? '',
      'packing_weight_kg': c.packingWeightKg,
      'pickup_location': c.loadingFrom,
      'delivery_location': c.loadingTo,
      'buyer_remark': c.buyerRemark,
      'seller_remark': c.sellerRemark,
      'admin_remark': c.adminRemark,
    };
    _text = {for (final e in _original.entries) e.key: TextEditingController(text: e.value)};
    final status = c.status.toLowerCase();
    _status = _statuses.containsKey(status) ? status : 'active';
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _ymd(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final body = <String, dynamic>{};
    _text.forEach((key, controller) {
      final value = controller.text.trim();
      if (value != _original[key]!.trim()) body[key] = value;
    });
    // Bags + packing weight set the quantity on the backend, so quantity is only sent on its own.
    if (body.containsKey('bag_count') || body.containsKey('packing_weight_kg')) {
      body
        ..remove('deal_quantity')
        ..putIfAbsent('bag_count', () => _text['bag_count']!.text.trim())
        ..putIfAbsent('packing_weight_kg', () => _text['packing_weight_kg']!.text.trim());
    }
    _dates.forEach((key, value) {
      if (value != null) body[key] = _ymd(value);
    });
    if (_status != widget.contract.status.toLowerCase()) body['status'] = _status;
    if (body.isEmpty) {
      Get.snackbar('No changes', 'Nothing was changed.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await ApiClient.patch(
        endpoint: '/api/admin/contracts/${widget.contract.id}/edit/',
        data: body,
        requireAuth: true,
      );
      final controller = Get.find<ContractController>();
      await controller.fetchContractDetail(widget.contract.id);
      controller.fetchContracts();
      Get.snackbar('Contract updated', (response['message'] ?? 'Contract updated successfully.').toString(),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade700, colorText: Colors.white);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar('Update failed', e.toString().replaceFirst('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${c.contractId}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _section('Deal'),
            Row(children: [
              Expanded(flex: 3, child: _number('deal_amount', 'Rate / Price', decimal: true)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _readOnly('Per', c.amountUnit.toUpperCase())),
            ]),
            Row(children: [
              Expanded(flex: 3, child: _number('deal_quantity', 'Quantity', decimal: true)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _readOnly('Unit', c.quantityUnit.toUpperCase())),
            ]),
            Row(children: [
              Expanded(child: _number('bag_count', 'Bags')),
              const SizedBox(width: 10),
              Expanded(child: _number('packing_weight_kg', 'Packing weight (KG)', decimal: true)),
            ]),
            _section('Locations & Dates'),
            _textField('pickup_location', 'Pickup location', required: true),
            _textField('delivery_location', 'Delivery location', required: true),
            _dateField('loading_from_date', 'Loading from date'),
            _dateField('loading_to_date', 'Loading to date'),
            _dateField('delivery_date', 'Delivery date'),
            _section('Status & Remarks'),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (value) => _status = value ?? _status,
              ),
            ),
            _textField('buyer_remark', 'Buyer remark', maxLines: 2),
            _textField('seller_remark', 'Seller remark', maxLines: 2),
            _textField('admin_remark', 'Admin remark', maxLines: 2),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InputDecorator(decoration: InputDecoration(labelText: label), child: Text(value.isEmpty ? '-' : value)),
      );

  Widget _number(String key, String label, {bool decimal = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _text[key],
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'^\d*\.?\d{0,3}' : r'^\d*'))],
          maxLength: 10,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _textField(String key, String label, {bool required = false, int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _text[key],
          maxLines: maxLines,
          decoration: InputDecoration(labelText: required ? '$label *' : label, alignLabelWithHint: maxLines > 1),
          validator: (value) => required && (value ?? '').trim().isEmpty ? '$label is required' : null,
        ),
      );

  Widget _dateField(String key, String label) {
    final value = _dates[key];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 1),
            lastDate: DateTime(now.year + 2),
          );
          if (picked != null) setState(() => _dates[key] = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: value == null ? 'Leave empty to keep the current date' : null,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_month)
                : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dates[key] = null)),
          ),
          child: Text(value == null ? 'Select date' : _ymd(value)),
        ),
      ),
    );
  }
}
