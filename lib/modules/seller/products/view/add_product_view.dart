import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../common/seller_ui.dart';
import '../controller/seller_product_controller.dart';
import 'package:daalsetu/widgets/app_shell.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  static const Color primaryColor = AddProductView.primaryColor;
  late final SellerProductController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SellerProductController>();
    controller.clearForm();
    controller.fetchSupportData();
  }

  @override
  Widget build(BuildContext context) {
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
        leading: AppBarLeading(child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        )), leadingWidth: AppBarLeading.widthFor(context, hasChild: true),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.iconTheme.color),
            tooltip: "Reset Form",
            onPressed: () {
              controller.clearForm();
              controller.fetchSupportData();
            },
          ),
        ],
      ),
      body: Obx(() {
        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            controller.clearForm();
            await controller.fetchSupportData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Offer Details"),
              const SizedBox(height: 16),
              _buildTextField(
                controller.titleController,
                "Offer Title * (e.g. Premium Toor Dal)",
                IconlyLight.bag,
              ),
              _buildTextField(
                controller.descController,
                "Detailed Description",
                IconlyLight.document,
                minLines: 3,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: 8),
              _sectionTitle("Category & Brand"),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                hint: "Select Category *",
                value: controller.selectedCategoryId.value,
                items: controller.categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(controller.categoryLabel(cat)),
                      ),
                    )
                    .toList(),
                onChanged: controller.selectCategory,
                icon: IconlyLight.category,
              ),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                hint: controller.selectedCategoryId.value == null
                    ? "Select category first"
                    : controller.isBrandsLoading.value
                    ? "Loading brands..."
                    : controller.brands.isEmpty
                    ? "No mapped brands available"
                    : "Select Brand (optional)",
                value: controller.selectedBrandId.value,
                items: controller.brands
                    .map(
                      (brand) => DropdownMenuItem(
                        value: brand.id,
                        child: Text(brand.brandName),
                      ),
                    )
                    .toList(),
                onChanged:
                    controller.selectedCategoryId.value == null ||
                        controller.isBrandsLoading.value
                    ? null
                    : (val) => controller.selectedBrandId.value = val,
                icon: IconlyLight.info_square,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(IconlyLight.user_1, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Seller: ${controller.sellerName.value}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionTitle("Pricing & Quantity"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller.amountController,
                      "Price *",
                      IconlyLight.wallet,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDropdown<String>(
                        hint: "Per",
                        value: controller.amountUnit.value,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('per KG')),
                          DropdownMenuItem(
                            value: 'qtl',
                            child: Text('per Quintal'),
                          ),
                          DropdownMenuItem(
                            value: 'ton',
                            child: Text('per Ton'),
                          ),
                        ],
                        onChanged: controller.setOfferUnit,
                        icon: Icons.scale_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller.quantityController,
                      "Quantity *",
                      Icons.inventory_2_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDropdown<String>(
                        hint: "Quantity Unit",
                        value: controller.quantityUnit.value,
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('KG')),
                          DropdownMenuItem(value: 'qtl', child: Text('QTL')),
                          DropdownMenuItem(value: 'ton', child: Text('TON')),
                        ],
                        onChanged: controller.setOfferUnit,
                        icon: Icons.scale_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller.bagCountController,
                      "Bags",
                      IconlyLight.work,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller.packingWeightController,
                      "Packing (kg/bag)",
                      Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "Updating weight or bags dynamically keeps units in sync with total quantity.",
                style: TextStyle(fontSize: 12, color: theme.disabledColor),
              ),

              const SizedBox(height: 24),
              _sectionTitle("Loading & Validity"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context,
                      "Loading From *",
                      controller.loadingFrom.value,
                      (d) => controller.loadingFrom.value = d,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _dateField(
                      context,
                      "Loading To *",
                      controller.loadingTo.value,
                      (d) => controller.loadingTo.value = d,
                    ),
                  ),
                ],
              ),
              _expiryField(context, controller),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller.locationController,
                builder: (context, value, _) {
                  return _buildTextField(
                    controller.locationController,
                    "Search or enter loading location",
                    IconlyLight.location,
                    minLines: 1,
                    maxLines: 2,
                    hintMaxLines: 2,
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            key: const Key('clear_location_btn'),
                            icon: const Icon(Icons.clear, size: 18),
                            splashRadius: 18,
                            tooltip: "Clear location",
                            onPressed: () =>
                                controller.locationController.clear(),
                          )
                        : Icon(
                            Icons.search,
                            key: const Key('search_location_icon'),
                            size: 20,
                            color: Get.theme.disabledColor,
                          ),
                  );
                },
              ),
              _buildTextField(
                controller.remarkController,
                "Remark",
                IconlyLight.edit,
                maxLines: 2,
              ),

              const SizedBox(height: 8),
              _sectionTitle("Offer Media (Optional)"),
              const SizedBox(height: 16),
              _mediaPicker(
                label: "Offer Image",
                fileName: controller.fileName(
                  controller.selectedImagePath.value,
                ),
                icon: IconlyLight.image,
                onPick: controller.pickOfferImage,
                onClear: () => controller.selectedImagePath.value = null,
              ),
              _mediaPicker(
                label: "Offer Video",
                fileName: controller.fileName(
                  controller.selectedVideoPath.value,
                ),
                icon: IconlyLight.video,
                onPick: controller.pickOfferVideo,
                onClear: () => controller.selectedVideoPath.value = null,
              ),

              if (controller.companies.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionTitle("Company"),
                const SizedBox(height: 16),
                _buildDropdown<int>(
                  hint: "Select Company",
                  value: controller.selectedCompanyId.value,
                  items: controller.companies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.isPrimary
                                ? "${c.legalName} (Primary)"
                                : c.legalName,
                          ),
                        ),
                      )
                      .toList(),
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
                    final selected = controller.selectedBranchIds.contains(
                      b.id,
                    );
                    return FilterChip(
                      label: Text(b.locationName ?? b.branchCode ?? 'Branch'),
                      selected: selected,
                      selectedColor: primaryColor.withValues(alpha: 0.25),
                      checkmarkColor: const Color(0xFF172033),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFF172033)
                            : theme.colorScheme.onSurface,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: selected
                            ? primaryColor
                            : theme.colorScheme.outlineVariant,
                      ),
                      onSelected: (on) => on
                          ? controller.selectedBranchIds.add(b.id!)
                          : controller.selectedBranchIds.remove(b.id),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.createProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isSaving.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "CREATE OFFER",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData? icon, {
    int maxLines = 1,
    int? minLines,
    int? hintMaxLines,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    final bool isMultiLine =
        maxLines > 1 || (minLines != null && minLines > 1);
    final effectiveKeyboardType =
        isMultiLine && keyboardType == TextInputType.text
        ? TextInputType.multiline
        : keyboardType;
    final iconColor =
        Get.theme.iconTheme.color?.withValues(alpha: 0.6) ?? Colors.grey;
    final field = TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: isMultiLine
          ? TextInputAction.newline
          : TextInputAction.next,
      textAlignVertical:
          isMultiLine ? TextAlignVertical.top : TextAlignVertical.center,
      keyboardType: effectiveKeyboardType,
      maxLength:
          keyboardType == TextInputType.number ||
              keyboardType ==
                  const TextInputType.numberWithOptions(decimal: true)
          ? 10
          : null,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        constraints: isMultiLine
            ? const BoxConstraints(minHeight: 96)
            : const BoxConstraints(minHeight: 48),
        hintText: hint,
        hintMaxLines: hintMaxLines ?? maxLines,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Get.theme.hintColor.withValues(alpha: 0.8),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: icon != null && !isMultiLine
            ? SizedBox(
                width: 46,
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                ),
              )
            : null,
        prefixIconConstraints: icon != null && !isMultiLine
            ? const BoxConstraints(
                minWidth: 46,
                maxWidth: 46,
                minHeight: 48,
                maxHeight: 48,
              )
            : null,
        filled: true,
        fillColor: Get.theme.colorScheme.surface,
        contentPadding: EdgeInsets.only(
          left: isMultiLine && icon != null ? 46 : (icon != null ? 0 : 16),
          right: 16,
          top: isMultiLine ? 16 : 14,
          bottom: isMultiLine ? 16 : 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isMultiLine && icon != null
          ? Stack(
              children: [
                field,
                Positioned(
                  left: 14,
                  top: 14,
                  child: IgnorePointer(
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                ),
              ],
            )
          : field,
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
          decoration: BoxDecoration(
            color: Get.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(IconlyLight.calendar, size: 20, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.isEmpty ? label : value,
                  style: TextStyle(
                    color: value.isEmpty ? Get.theme.disabledColor : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaPicker({
    required String label,
    required String fileName,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName.isEmpty ? label : fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fileName.isNotEmpty)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
            TextButton(
              onPressed: onPick,
              child: Text(fileName.isEmpty ? "Choose" : "Change"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) {
    return _pickerBox(
      label,
      value == null
          ? ''
          : SellerUi.date(value.toIso8601String().substring(0, 10)),
      () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Widget _expiryField(
    BuildContext context,
    SellerProductController controller,
  ) {
    final value = controller.dealExpiry.value;
    return _pickerBox(
      "Deal Expiry (date & time) *",
      value == null ? '' : SellerUi.date(value.toIso8601String()),
      () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? now.add(const Duration(days: 3)),
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;
        final isToday = DateUtils.isSameDay(date, now);
        final minimumExpiry = now.add(const Duration(minutes: 2));
        final initialDateTime = value != null &&
                DateUtils.isSameDay(value, date) &&
                value.isAfter(now)
            ? value
            : isToday
                ? minimumExpiry
                : DateTime(date.year, date.month, date.day, 18);
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDateTime),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },
        );
        if (time == null) return;
        final selectedExpiry = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (!selectedExpiry.isAfter(DateTime.now())) {
          SellerUi.error('Deal expiry time must be in the future.');
          return;
        }
        controller.dealExpiry.value = selectedExpiry;
      },
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
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
