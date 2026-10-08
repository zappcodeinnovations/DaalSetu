import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/products/controller/product_controller.dart';
import 'package:daalsetu/modules/products/model/offer_option_model.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/services/product_services.dart';
import 'package:daalsetu/services/seller_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

/// Admin "Edit Offer": same fields as the web edit form (category, brand, price unit,
/// loading dates, deal expiry, remark, active). Stock is changed from "Update Stock".
class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  static const _units = {'qtl': 'Quintal', 'kg': 'KG', 'ton': 'Ton'};

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _location = TextEditingController();
  final _remark = TextEditingController();
  final _categoriesFuture = loadCategoryOptions();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _categoryId;
  String? _brandId;
  String _amountUnit = 'qtl';
  bool _isActive = true;
  DateTime? _loadingFrom;
  DateTime? _loadingTo;
  DateTime? _dealExpiry;
  Future<List<OfferOption>>? _brandsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _amount, _location, _remark]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final offer = await SellerServices.getOfferDetail(widget.product.id);
      _title.text = (offer['title'] ?? '').toString();
      _description.text = (offer['description'] ?? '').toString();
      _amount.text = (offer['amount'] ?? '').toString();
      _location.text = (offer['loading_location'] ?? '').toString();
      _remark.text = (offer['remark'] ?? '').toString();
      final unit = (offer['amount_unit'] ?? 'qtl').toString().toLowerCase();
      _amountUnit = _units.containsKey(unit) ? unit : 'qtl';
      _categoryId = _idOf(offer['category_id'] ?? offer['category']);
      _brandId = _idOf(offer['brand_id'] ?? offer['brand']);
      _isActive = offer['is_active'] != false;
      _loadingFrom = DateTime.tryParse((offer['loading_from'] ?? '').toString());
      _loadingTo = DateTime.tryParse((offer['loading_to'] ?? '').toString());
      _dealExpiry = DateTime.tryParse((offer['deal_expiry_datetime'] ?? '').toString())?.toLocal();
      if (_categoryId != null) _brandsFuture = ProductService.getCategoryBrands(int.parse(_categoryId!));
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  String? _idOf(Object? value) {
    if (value is Map) value = value['id'];
    final text = (value ?? '').toString();
    return text.isEmpty || text == 'null' ? null : text;
  }

  String _ymd(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _show(DateTime? d, {bool time = false}) {
    if (d == null) return '';
    final date = "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
    return time ? "$date ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}" : date;
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
  }

  Future<void> _pickExpiry() async {
    final date = await _pickDate(_dealExpiry);
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dealExpiry ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() => _dealExpiry = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_loadingFrom == null) {
      _error('Loading from date is required.');
      return;
    }
    if (_loadingTo != null && _loadingTo!.isBefore(_loadingFrom!)) {
      _error('Loading to cannot be before loading from.');
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'category_id': int.tryParse(_categoryId ?? ''),
      'brand_id': int.tryParse(_brandId ?? ''),
      'amount': _amount.text.trim(),
      'amount_unit': _amountUnit,
      'loading_from': _ymd(_loadingFrom!),
      'loading_to': _ymd(_loadingTo ?? _loadingFrom!),
      'loading_location': _location.text.trim(),
      'remark': _remark.text.trim(),
      'is_active': _isActive,
      if (_dealExpiry != null)
        'deal_expiry_datetime':
            "${_ymd(_dealExpiry!)}T${_dealExpiry!.hour.toString().padLeft(2, '0')}:${_dealExpiry!.minute.toString().padLeft(2, '0')}",
    };
    try {
      final result = await SellerServices.updateOffer(widget.product.id, body);
      if (Get.isRegistered<ProductController>()) await Get.find<ProductController>().fetchProducts();
      Get.snackbar('Offer updated', (result['message'] ?? '${_title.text.trim()} was updated.').toString(),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade700, colorText: Colors.white);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _error(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(String message) => Get.snackbar('Update failed', message,
      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade700, colorText: Colors.white);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Offer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _loadError = null;
                          });
                          _load();
                        },
                        child: const Text('Retry'),
                      ),
                    ]),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            _field(_title, 'Offer title *', IconlyLight.bag, validator: _required),
                            _field(_description, 'Description', IconlyLight.document, maxLines: 3),
                            _categoryDropdown(),
                            _brandDropdown(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _field(
                                    _amount,
                                    'Price *',
                                    IconlyLight.wallet,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    validator: (value) {
                                      final amount = double.tryParse(value?.trim() ?? '');
                                      return amount == null || amount <= 0 ? 'Enter a valid price' : null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _amountUnit,
                                      decoration: const InputDecoration(labelText: 'Per'),
                                      items: _units.entries
                                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                          .toList(),
                                      onChanged: (value) => _amountUnit = value ?? 'qtl',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _dateTile('Loading from *', _show(_loadingFrom), () async {
                              final picked = await _pickDate(_loadingFrom);
                              if (picked != null) setState(() => _loadingFrom = picked);
                            }),
                            _dateTile('Loading to', _show(_loadingTo), () async {
                              final picked = await _pickDate(_loadingTo ?? _loadingFrom);
                              if (picked != null) setState(() => _loadingTo = picked);
                            }),
                            _field(_location, 'Loading location', IconlyLight.location),
                            _dateTile('Deal expiry', _show(_dealExpiry, time: true), _pickExpiry),
                            _field(_remark, 'Remark', IconlyLight.paper, maxLines: 2),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Offer active'),
                              subtitle: const Text('Buyers can see active offers'),
                              value: _isActive,
                              onChanged: (value) => setState(() => _isActive = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving changes...' : 'Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _categoryDropdown() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FutureBuilder<List<AdminOption>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            final options = snapshot.data ?? const <AdminOption>[];
            return DropdownButtonFormField<String>(
              initialValue: options.any((o) => o.value == _categoryId) ? _categoryId : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category *',
                prefixIcon: const Icon(IconlyLight.category),
                helperText: snapshot.connectionState == ConnectionState.done ? null : 'Loading categories...',
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (value) => setState(() {
                _categoryId = value;
                _brandId = null;
                _brandsFuture = value == null ? null : ProductService.getCategoryBrands(int.parse(value));
              }),
              validator: (value) => value == null ? 'Category is required' : null,
            );
          },
        ),
      );

  Widget _brandDropdown() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FutureBuilder<List<OfferOption>>(
          // Keyed by category so the brand list reloads when the category changes.
          key: ValueKey(_categoryId),
          future: _brandsFuture,
          builder: (context, snapshot) {
            final brands = snapshot.data ?? const <OfferOption>[];
            return DropdownButtonFormField<String>(
              initialValue: brands.any((b) => '${b.id}' == _brandId) ? _brandId : '',
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Brand',
                prefixIcon: const Icon(Icons.sell_outlined),
                helperText: _categoryId != null && snapshot.connectionState != ConnectionState.done ? 'Loading brands...' : null,
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('No brand')),
                ...brands.map((b) => DropdownMenuItem(value: '${b.id}', child: Text(b.name, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (value) => _brandId = (value ?? '').isEmpty ? null : value,
            );
          },
        ),
      );

  Widget _dateTile(String label, String value, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(IconlyLight.calendar),
              suffixIcon: const Icon(Icons.edit_calendar_outlined),
            ),
            child: Text(value.isEmpty ? 'Select' : value),
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), alignLabelWithHint: maxLines > 1),
      ),
    );
  }

  String? _required(String? value) => (value?.trim().isEmpty ?? true) ? 'This field is required' : null;
}
