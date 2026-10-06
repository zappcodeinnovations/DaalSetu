import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../common/seller_ui.dart';
import '../controller/seller_product_controller.dart';

class AddProductView extends StatelessWidget {
  const AddProductView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SellerProductController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Create Offer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Offer Details"),
              const SizedBox(height: 16),
              _buildTextField(controller.titleController, "Offer Title * (e.g. Premium Toor Dal)", IconlyLight.bag),
              _buildTextField(controller.descController, "Detailed Description", IconlyLight.document, maxLines: 3),

              const SizedBox(height: 8),
              _sectionTitle("Category & Brand"),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                hint: "Select Category *",
                value: controller.selectedCategoryId.value,
                items: controller.categories.map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Text(cat.name),
                )).toList(),
                onChanged: (val) => controller.selectedCategoryId.value = val,
                icon: IconlyLight.category,
              ),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                hint: "Select Brand (optional)",
                value: controller.selectedBrandId.value,
                items: controller.brands.map((brand) => DropdownMenuItem(
                  value: brand.id,
                  child: Text(brand.brandName),
                )).toList(),
                onChanged: (val) => controller.selectedBrandId.value = val,
                icon: IconlyLight.info_square,
              ),

              const SizedBox(height: 24),
              _sectionTitle("Pricing & Quantity"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller.amountController, "Price *", IconlyLight.wallet, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDropdown<String>(
                        hint: "Per",
                        value: controller.amountUnit.value,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('per KG')),
                          DropdownMenuItem(value: 'qtl', child: Text('per Quintal')),
                          DropdownMenuItem(value: 'ton', child: Text('per Ton')),
                        ],
                        onChanged: (val) => controller.amountUnit.value = val ?? 'qtl',
                        icon: Icons.scale_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller.bagCountController, "Bags", IconlyLight.work, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller.packingWeightController, "Packing (kg/bag)", Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              _buildTextField(controller.quantityController, "Or total quantity (when not using bags)", Icons.inventory_2_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              Text(
                "With bags, quantity is calculated as bags × packing weight.",
                style: TextStyle(fontSize: 12, color: theme.disabledColor),
              ),

              const SizedBox(height: 24),
              _sectionTitle("Loading & Validity"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _dateField(context, "Loading From *", controller.loadingFrom.value, (d) => controller.loadingFrom.value = d)),
                  const SizedBox(width: 16),
                  Expanded(child: _dateField(context, "Loading To *", controller.loadingTo.value, (d) => controller.loadingTo.value = d)),
                ],
              ),
              _expiryField(context, controller),
              _buildTextField(controller.locationController, "Loading Location", IconlyLight.location),
              _buildTextField(controller.remarkController, "Remark", IconlyLight.edit, maxLines: 2),

              if (controller.companies.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionTitle("Company"),
                const SizedBox(height: 16),
                _buildDropdown<int>(
                  hint: "Select Company",
                  value: controller.selectedCompanyId.value,
                  items: controller.companies.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.isPrimary ? "${c.legalName} (Primary)" : c.legalName),
                  )).toList(),
                  onChanged: (val) => controller.selectedCompanyId.value = val,
                  icon: IconlyLight.work,
                ),
              ],

              if (controller.branches.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sectionTitle("Visible in Branches"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.branches.map((b) {
                    final selected = controller.selectedBranchIds.contains(b.id);
                    return FilterChip(
                      label: Text(b.locationName ?? b.branchCode ?? 'Branch'),
                      selected: selected,
                      selectedColor: primaryColor.withValues(alpha: 0.25),
                      onSelected: (on) => on ? controller.selectedBranchIds.add(b.id!) : controller.selectedBranchIds.remove(b.id),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value ? null : controller.createProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          "CREATE OFFER",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData? icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        ),
      ),
    );
  }

  Widget _pickerBox(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(IconlyLight.calendar, size: 20, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value.isEmpty ? label : value,
                    style: TextStyle(color: value.isEmpty ? Get.theme.disabledColor : null)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(BuildContext context, String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    return _pickerBox(label, value == null ? '' : SellerUi.date(value.toIso8601String().substring(0, 10)), () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? now,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked != null) onPicked(picked);
    });
  }

  Widget _expiryField(BuildContext context, SellerProductController controller) {
    final value = controller.dealExpiry.value;
    return _pickerBox("Deal Expiry (date & time) *", value == null ? '' : SellerUi.date(value.toIso8601String()), () async {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: value ?? now.add(const Duration(days: 3)),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 365)),
      );
      if (date == null || !context.mounted) return;
      final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
      if (time == null) return;
      controller.dealExpiry.value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: Get.theme.disabledColor),
              const SizedBox(width: 12),
              Text(hint, style: TextStyle(color: Get.theme.disabledColor)),
            ],
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Get.theme.cardColor,
        ),
      ),
    );
  }
}
