import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../widgets/app_shell.dart';

class EditBuyerRequirementView extends StatefulWidget {
  const EditBuyerRequirementView({super.key, required this.requirement});
  final Map<String, dynamic> requirement;

  @override
  State<EditBuyerRequirementView> createState() =>
      _EditBuyerRequirementViewState();
}

class _EditBuyerRequirementViewState extends State<EditBuyerRequirementView> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;
  int _validity = 7;
  static const _labels = {
    'title': 'Requirement title',
    'description': 'Description',
    'required_quantity': 'Quantity',
    'target_price': 'Target price',
    'required_bag_count': 'Bags',
    'packing_weight_kg': 'Packing weight (kg)',
    'delivery_terms': 'Delivery terms',
    'buyer_remark': 'Remark',
  };

  @override
  void initState() {
    super.initState();
    for (final key in _labels.keys) {
      _controllers[key] = TextEditingController(
        text: widget.requirement[key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await BuyerServices.updateBuyerRequirement(widget.requirement['id'], {
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
        'expiry_days': _validity,
      });
      if (!mounted) return;
      Get.back(result: true);
      AppSnackbar.showSuccess(message: 'Requirement updated successfully');
    } catch (error) {
      if (mounted) AppSnackbar.showError(message: error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBarLeading(),
      leadingWidth: AppBarLeading.widthFor(context),
      title: const Text('Edit Requirement'),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Quantity unit: ${widget.requirement['quantity_unit'] ?? 'qtl'} • Price per ${widget.requirement['price_unit'] ?? 'qtl'}',
          ),
          const SizedBox(height: 16),
          for (final entry in _labels.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _controllers[entry.key],
                decoration: InputDecoration(
                  labelText: entry.value,
                  border: const OutlineInputBorder(),
                ),
                enabled: !_saving,
                keyboardType:
                    const [
                      'required_quantity',
                      'target_price',
                      'required_bag_count',
                      'packing_weight_kg',
                    ].contains(entry.key)
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                validator: (value) {
                  if (entry.key == 'title' && (value ?? '').trim().isEmpty)
                    return 'Enter a title';
                  if (const [
                    'required_quantity',
                    'target_price',
                  ].contains(entry.key)) {
                    final number = num.tryParse(value ?? '');
                    if (number == null || !number.isFinite || number <= 0)
                      return 'Enter a value greater than zero';
                  }
                  return null;
                },
              ),
            ),
          DropdownButtonFormField<int>(
            initialValue: _validity,
            decoration: const InputDecoration(
              labelText: 'Renew validity from today',
              border: OutlineInputBorder(),
            ),
            items: [1, 3, 7, 14, 30]
                .map(
                  (days) =>
                      DropdownMenuItem(value: days, child: Text('$days days')),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _validity = value ?? 7),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save Changes'),
          ),
        ],
      ),
    ),
  );
}
