import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/buyer_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../widgets/app_shell.dart';
import '../../../../widgets/hero_header.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const HeroHeader(
        leading: AppBarLeading(),
        title: 'Edit Requirement',
        subtitle: 'Update requirement specifications & validity',
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFFE0B2),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quantity unit: ${widget.requirement['quantity_unit'] ?? 'qtl'} • Price per ${widget.requirement['price_unit'] ?? 'qtl'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final entry in _labels.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _controllers[entry.key],
                  decoration: InputDecoration(
                    labelText: entry.value,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFEA580C),
                        width: 1.5,
                      ),
                    ),
                  ),
                  enabled: !_saving,
                  keyboardType: const [
                    'required_quantity',
                    'target_price',
                    'required_bag_count',
                    'packing_weight_kg',
                  ].contains(entry.key)
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  validator: (value) {
                    if (entry.key == 'title' && (value ?? '').trim().isEmpty) {
                      return 'Enter a title';
                    }
                    if (const [
                      'required_quantity',
                      'target_price',
                    ].contains(entry.key)) {
                      final number = num.tryParse(value ?? '');
                      if (number == null || !number.isFinite || number <= 0) {
                        return 'Enter a value greater than zero';
                      }
                    }
                    return null;
                  },
                ),
              ),
            DropdownButtonFormField<int>(
              initialValue: _validity,
              decoration: InputDecoration(
                labelText: 'Renew validity from today',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFEA580C),
                    width: 1.5,
                  ),
                ),
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
            const SizedBox(height: 24),
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFF59E0B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving...' : 'Save Changes',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
