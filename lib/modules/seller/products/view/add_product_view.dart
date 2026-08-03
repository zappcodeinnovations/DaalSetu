import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
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
          "Add New Product",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Product Details"),
              const SizedBox(height: 16),
              _buildTextField(controller.titleController, "Product Title (e.g. Premium Toor Dal)", IconlyLight.bag),
              _buildTextField(controller.descController, "Detailed Description", IconlyLight.document, maxLines: 3),
              
              const SizedBox(height: 24),
              _sectionTitle("Category & Brand"),
              const SizedBox(height: 16),
              _buildDropdown<int>(
                hint: "Select Category",
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
                hint: "Select Brand",
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
                  Expanded(child: _buildTextField(controller.amountController, "Amount", IconlyLight.wallet, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller.unitController, "Unit (e.g. qtl)", null)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller.bagCountController, "Bag Count", IconlyLight.work, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller.packingWeightController, "Packing (kg)", Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                ],
              ),

              const SizedBox(height: 24),
              _sectionTitle("Logistics"),
              const SizedBox(height: 16),
              _buildTextField(controller.locationController, "Loading Location", IconlyLight.location),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.createProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "LIST PRODUCT",
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
