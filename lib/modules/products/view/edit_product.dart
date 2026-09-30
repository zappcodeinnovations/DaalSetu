import 'package:agro_broker/modules/products/controller/product_controller.dart';
import 'package:agro_broker/modules/products/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.put(ProductController());
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.product.title);
    _description = TextEditingController(text: widget.product.description);
    _amount = TextEditingController(text: widget.product.amount);
    _location = TextEditingController(text: widget.product.loadingLocation);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await _controller.updateProduct(
      product: widget.product,
      title: _title.text.trim(),
      description: _description.text.trim(),
      amount: _amount.text.trim(),
      location: _location.text.trim(),
    );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit product')),
      body: Form(
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
                  _field(
                    controller: _title,
                    label: 'Product title',
                    icon: IconlyLight.bag,
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _description,
                    label: 'Description (optional)',
                    icon: IconlyLight.document,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _amount,
                    label: 'Amount',
                    icon: IconlyLight.wallet,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      final amount = double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _location,
                    label: 'Loading location',
                    icon: IconlyLight.location,
                    validator: _required,
                  ),
                  if (widget.product.category != null) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(IconlyLight.category),
                      title: const Text('Category'),
                      subtitle: Text(widget.product.category!.name),
                      trailing: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              final saving =
                  _controller.processingProductId.value == widget.product.id;
              return SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving changes...' : 'Save changes'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'This field is required' : null;
}
