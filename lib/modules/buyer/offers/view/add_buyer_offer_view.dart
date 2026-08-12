import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart'; // To reuse category/brand fetchers
import '../../../seller/categories/model/seller_category_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AddBuyerOfferScreen extends StatefulWidget {
  const AddBuyerOfferScreen({super.key});

  @override
  State<AddBuyerOfferScreen> createState() => _AddBuyerOfferScreenState();
}

class _AddBuyerOfferScreenState extends State<AddBuyerOfferScreen> {
  final titleController = TextEditingController();
  final quantityController = TextEditingController();
  final amountController = TextEditingController();
  final bagCountController = TextEditingController();
  final packingController = TextEditingController();

  int? selectedCategoryId;
  int? selectedBrandId;
  String selectedUnit = "qtl";
  String selectedAmountUnit = "ton";

  List<CategoryTreeModel> categories = [];
  List<BrandModel> brands = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupportData();
  }

  Future<void> _loadSupportData() async {
    try {
      final catData = await SellerServices.getCategoriesTree();
      
      List<BrandModel> fetchedBrands = [];
      try {
        final brandData = await SellerServices.getBrandsDropdown();
        fetchedBrands = brandData.map((e) => BrandModel.fromJson(e)).toList();
      } catch (e) {
        print("⚠️ Brand API failed or returned empty: $e");
        // We continue even if brands fail, categories are more important
      }
      
      setState(() {
        categories = catData.map((e) => CategoryTreeModel.fromJson(e)).toList();
        brands = fetchedBrands;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Notice", "Could not load full support data, but you can still try posting.");
    }
  }

  Future<void> _submit() async {
    if (titleController.text.isEmpty || selectedCategoryId == null) {
      Get.snackbar("Error", "Please fill required fields");
      return;
    }

    try {
      setState(() => isLoading = true);
      final body = {
        "title": titleController.text.trim(),
        "category_id": selectedCategoryId,
        "brand_id": selectedBrandId,
        "requested_quantity": quantityController.text.trim(),
        "quantity_unit": selectedUnit,
        "requested_amount": amountController.text.trim(),
        "amount_unit": selectedAmountUnit,
        "requested_bag_count": int.tryParse(bagCountController.text.trim()) ?? 0,
        "packing_weight_kg": packingController.text.trim(),
        "target_branch_ids": [], // Can be extended if branches are loaded
      };

      await BuyerServices.createOffer(body);
      Get.back();
      Get.snackbar("Success", "Requirement posted successfully");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Post Requirement", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: isLoading && categories.isEmpty
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(titleController, "Requirement Title (e.g. Need Toor Dal)", IconlyLight.edit),
                  const SizedBox(height: 16),
                  
                  _buildDropdown<int>(
                    hint: "Select Category",
                    value: selectedCategoryId,
                    items: categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                    onChanged: (val) => setState(() => selectedCategoryId = val),
                    icon: IconlyLight.category,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown<int>(
                    hint: brands.isEmpty ? "No Brands Found" : "Select Brand",
                    value: selectedBrandId,
                    items: brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.brandName))).toList(),
                    onChanged: brands.isEmpty ? null : (val) => setState(() => selectedBrandId = val),
                    icon: IconlyLight.info_square,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildTextField(quantityController, "Quantity", IconlyLight.buy, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown<String>(
                          hint: "Unit",
                          value: selectedUnit,
                          items: ["qtl", "ton", "kg"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => selectedUnit = val!),
                          icon: Icons.unfold_more,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildTextField(amountController, "Target Price", IconlyLight.wallet, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown<String>(
                          hint: "Per",
                          value: selectedAmountUnit,
                          items: ["qtl", "ton", "kg"].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (val) => setState(() => selectedAmountUnit = val!),
                          icon: Icons.unfold_more,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildTextField(bagCountController, "Bags", IconlyLight.work, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(packingController, "Packing (kg)", Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("POST REQUIREMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown<T>({required String hint, required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?>? onChanged, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(children: [Icon(icon, size: 20, color: Get.theme.disabledColor), const SizedBox(width: 12), Text(hint)]),
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
