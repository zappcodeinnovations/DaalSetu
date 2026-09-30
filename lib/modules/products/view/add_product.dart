import 'dart:io';

import 'package:agro_broker/modules/products/controller/product_controller.dart';
import 'package:agro_broker/modules/products/model/offer_option_model.dart';
import 'package:agro_broker/services/product_services.dart';
import 'package:flutter/material.dart';
import 'package:agro_broker/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _productController = Get.put(ProductController());

  final _title = TextEditingController();
  final _rate = TextEditingController();
  final _quantity = TextEditingController();
  final _bags = TextEditingController();
  final _packingWeight = TextEditingController(text: '30');
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _remark = TextEditingController();

  List<OfferOption> categories = [];
  List<OfferOption> brands = [];
  List<OfferOption> sellers = [];
  List<OfferOption> companies = [];
  List<OfferBranch> branches = [];
  OfferOption? category;
  OfferOption? brand;
  OfferOption? seller;
  OfferOption? company;
  final Set<int> selectedBranchIds = {};
  DateTime? loadingFrom;
  DateTime? loadingTo;
  DateTime? expiry;
  File? image;
  File? video;
  String rateUnit = 'ton';
  String quantityUnit = 'ton';
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final result = await Future.wait([
        ProductService.getParentCategories(),
        ProductService.getSellers(),
      ]);
      categories = result[0];
      sellers = result[1];
    } catch (_) {
      _message('Unable to load offer options', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectCategory(OfferOption? value) async {
    setState(() {
      category = value;
      brand = null;
      brands = [];
    });
    if (value == null) return;
    final result = await ProductService.getCategoryBrands(value.id);
    if (mounted) setState(() => brands = result);
  }

  Future<void> _selectSeller(OfferOption? value) async {
    setState(() {
      seller = value;
      company = null;
      companies = [];
      branches = [];
      selectedBranchIds.clear();
    });
    if (value == null) return;
    final result = await Future.wait([
      ProductService.getSellerCompanies(value.id),
      ProductService.getSellerBranches(value.id),
    ]);
    if (!mounted) return;
    setState(() {
      companies = result[0];
      branches = result[1] as List<OfferBranch>;
      selectedBranchIds.addAll(branches.map((item) => item.id));
    });
  }

  void _syncFromQuantity(String value) {
    final quantity = double.tryParse(value);
    final weight = double.tryParse(_packingWeight.text);
    if (quantity == null || weight == null || weight <= 0) return;
    final quantityKg = switch (quantityUnit) {
      'ton' => quantity * 1000,
      'qtl' => quantity * 100,
      _ => quantity,
    };
    _bags.text = (quantityKg / weight).round().toString();
  }

  Future<void> _pickDate(String type) async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (value == null) return;
    setState(() {
      if (type == 'from') loadingFrom = value;
      if (type == 'to') loadingTo = value;
      if (type == 'expiry') expiry = value;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (category == null || seller == null || company == null) {
      _message('Category, seller and company are required.', error: true);
      return;
    }
    if (loadingFrom == null || loadingTo == null || expiry == null) {
      _message('Select all loading and expiry dates.', error: true);
      return;
    }
    if (loadingTo!.isBefore(loadingFrom!)) {
      _message('Loading To date cannot be before Loading From.', error: true);
      return;
    }
    if (branches.isNotEmpty && selectedBranchIds.isEmpty) {
      _message('Select at least one visible branch.', error: true);
      return;
    }

    setState(() => saving = true);
    try {
      final bagCount = int.parse(_bags.text);
      final response = await ProductService.createOffer({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'category_id': category!.id,
        'root_category_id': category!.id,
        if (brand != null) 'brand': brand!.id,
        'seller': seller!.id,
        'company': company!.id,
        'visible_branches': selectedBranchIds.toList(),
        'amount': _rate.text.trim(),
        'amount_unit': rateUnit,
        'quantity': _quantity.text.trim(),
        'original_bag_count': bagCount,
        'remaining_bag_count': bagCount,
        'packing_weight_kg': _packingWeight.text.trim(),
        'quantity_unit': quantityUnit,
        'loading_from': _apiDate(loadingFrom!),
        'loading_to': _apiDate(loadingTo!),
        'deal_expiry_datetime': _apiDate(expiry!),
        'loading_location': _location.text.trim(),
        'remark': _remark.text.trim(),
        'status': 'available',
        'is_active': true,
      });
      final id = response['id'] as int?;
      if (id == null) throw Exception('Offer ID missing');
      if (image != null) {
        await ProductService.uploadProductImage(
          productId: id,
          imagePath: image!.path,
          isPrimary: true,
        );
      }
      if (video != null) {
        await ProductService.uploadProductVideo(
          productId: id,
          videoPath: video!.path,
        );
      }
      await _productController.fetchProducts();
      if (mounted) Navigator.pop(context);
      _message('Offer created successfully.');
    } catch (error) {
      _message(_friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create offer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Offer information', [
              _text(_title, 'Offer item', required: true),
              _dropdown(
                'Parent category',
                category,
                categories,
                _selectCategory,
              ),
              _dropdown(
                'Brand',
                brand,
                brands,
                (value) => setState(() => brand = value),
                enabled: category != null,
              ),
              _dropdown('Seller', seller, sellers, _selectSeller),
              _dropdown(
                'Company name',
                company,
                companies,
                (value) => setState(() => company = value),
                enabled: seller != null,
              ),
              _branches(),
            ]),
            _section('Pricing & quantity', [
              Row(
                children: [
                  Expanded(
                    child: _text(_rate, 'Rate', number: true, required: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _unit(
                      'Rate unit',
                      rateUnit,
                      (v) => setState(() => rateUnit = v!),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _text(
                      _quantity,
                      'Offer quantity',
                      number: true,
                      required: true,
                      onChanged: _syncFromQuantity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _unit('Quantity unit', quantityUnit, (v) {
                      setState(() => quantityUnit = v!);
                      _syncFromQuantity(_quantity.text);
                    }),
                  ),
                ],
              ),
            ]),
            _section('Loading & delivery', [
              _dateTile(
                'Loading from date',
                loadingFrom,
                () => _pickDate('from'),
              ),
              _dateTile('Loading to date', loadingTo, () => _pickDate('to')),
              _dateTile('Deal expiry date', expiry, () => _pickDate('expiry')),
              Row(
                children: [
                  Expanded(
                    child: _text(_bags, 'Bags', number: true, required: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _text(
                      _packingWeight,
                      'Packing weight (kg)',
                      number: true,
                      required: true,
                      onChanged: (_) => _syncFromQuantity(_quantity.text),
                    ),
                  ),
                ],
              ),
              _text(_location, 'Loading location', required: true),
            ]),
            _section('Offer media (optional)', [
              _mediaTile(
                'Offer image',
                image?.path,
                Icons.image_outlined,
                () async {
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) setState(() => image = File(file.path));
                },
              ),
              _mediaTile(
                'Offer video',
                video?.path,
                Icons.video_library_outlined,
                () async {
                  final file = await _picker.pickVideo(
                    source: ImageSource.gallery,
                  );
                  if (file != null) setState(() => video = File(file.path));
                },
              ),
            ]),
            _section('Notes', [
              _text(_description, 'Description', maxLines: 3),
              _text(_remark, 'Remark', maxLines: 3),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: saving ? null : _submit,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_business_rounded),
                label: Text(saving ? 'Creating offer...' : 'Create offer'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Divider(height: 24),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    inputFormatters: number
        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))]
        : null,
    onChanged: onChanged,
    validator: required
        ? (value) =>
              (value?.trim().isEmpty ?? true) ? '$label is required' : null
        : null,
    decoration: InputDecoration(
      labelText: '$label${required ? ' *' : ''}',
      alignLabelWithHint: maxLines > 1,
    ),
  );

  Widget _dropdown(
    String label,
    OfferOption? value,
    List<OfferOption> items,
    ValueChanged<OfferOption?> onChanged, {
    bool enabled = true,
  }) => DropdownButtonFormField<OfferOption>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: '$label *'),
    items: items
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(
              item.subtitle.isEmpty
                  ? item.name
                  : '${item.name} • ${item.subtitle}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: enabled ? onChanged : null,
    validator: (selected) => selected == null ? 'Select $label' : null,
  );

  Widget _unit(String label, String value, ValueChanged<String?> onChanged) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: 'kg', child: Text('KG')),
          DropdownMenuItem(value: 'qtl', child: Text('QUINTAL')),
          DropdownMenuItem(value: 'ton', child: Text('TON')),
        ],
        onChanged: onChanged,
      );

  Widget _branches() {
    if (seller == null) {
      return const Text('Select seller to load visible branches.');
    }
    if (branches.isEmpty) {
      return const Text('No branch available for this seller.');
    }
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Visible branches *'),
      child: Wrap(
        spacing: 8,
        children: branches
            .map(
              (branch) => FilterChip(
                selected: selectedBranchIds.contains(branch.id),
                label: Text('${branch.name} (${branch.code})'),
                onSelected: (selected) => setState(() {
                  selected
                      ? selectedBranchIds.add(branch.id)
                      : selectedBranchIds.remove(branch.id);
                }),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(date == null ? 'Select date' : _apiDate(date)),
        trailing: const Icon(Icons.calendar_month_outlined),
        onTap: onTap,
      );

  Widget _mediaTile(
    String label,
    String? path,
    IconData icon,
    VoidCallback onTap,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(
      path == null
          ? 'No file selected'
          : path.split(Platform.pathSeparator).last,
    ),
    trailing: const Icon(Icons.upload_file_rounded),
    onTap: onTap,
  );

  String _apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _friendlyError(Object error) {
    final text = error.toString();
    final match = RegExp(r'"([^"]+)":\s*\["([^"]+)"\]').firstMatch(text);
    return match == null
        ? 'Offer could not be created. Please verify all fields.'
        : '${match.group(1)}: ${match.group(2)}';
  }

  void _message(String message, {bool error = false}) {
    Get.snackbar(
      error ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _rate,
      _quantity,
      _bags,
      _packingWeight,
      _location,
      _description,
      _remark,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
