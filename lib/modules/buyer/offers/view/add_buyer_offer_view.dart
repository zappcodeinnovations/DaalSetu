import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart';
import '../../../../services/product_services.dart';
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
  List<Map<String, dynamic>> availableBranches = [];
  final Set<int> selectedBranchIds = {};
  bool isLoading = true;
  bool isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadSupportData();
  }

  Future<void> _loadSupportData() async {
    try {
      final catData = await SellerServices.getCategoriesTree();
      
      // Load branches
      List<Map<String, dynamic>> branchList = [];
      try {
        final branchRes = await SellerServices.getBranches();
        if (branchRes['data'] is Map<String, dynamic>) {
          final data = branchRes['data'] as Map<String, dynamic>;
          if (data['my_branches'] is List) {
            for (var b in data['my_branches']) {
              if (b is Map<String, dynamic>) branchList.add(b);
            }
          }
          if (data['primary_branch'] is Map<String, dynamic>) {
            final pb = data['primary_branch'] as Map<String, dynamic>;
            if (!branchList.any((e) => e['id'] == pb['id'])) {
              branchList.insert(0, pb);
            }
          }
        }
      } catch (e) {
        print("⚠️ Branches fetch error: $e");
      }

      setState(() {
        categories = catData.map((e) => CategoryTreeModel.fromJson(e)).toList();
        availableBranches = branchList;
        // Default select all available branches
        for (var b in branchList) {
          if (b['id'] != null) {
            final id = int.tryParse(b['id'].toString());
            if (id != null) selectedBranchIds.add(id);
          }
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("Notice", "Loaded available form fields.");
    }
  }

  Future<void> _onCategoryChanged(int? catId) async {
    setState(() {
      selectedCategoryId = catId;
      selectedBrandId = null;
      brands = [];
    });

    if (catId == null) return;

    try {
      final catBrands = await ProductService.getCategoryBrands(catId);
      if (mounted) {
        setState(() {
          brands = catBrands.map((b) => BrandModel(id: b.id, brandName: b.name)).toList();
        });
      }
    } catch (e) {
      print("⚠️ Category brands fetch error: $e");
    }
  }

  Future<void> _submit() async {
    if (titleController.text.trim().isEmpty || selectedCategoryId == null) {
      Get.snackbar("Error", "Please fill required fields (Title and Category)",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      setState(() => isPosting = true);
      final qtyNum = num.tryParse(quantityController.text.trim()) ?? 0;
      final amountNum = num.tryParse(amountController.text.trim()) ?? 0;
      final bagCount = int.tryParse(bagCountController.text.trim()) ?? 0;
      final packingKg = num.tryParse(packingController.text.trim());

      // Target branches resolution
      List<int> targetBranches = [];
      if (selectedBranchIds.isNotEmpty) {
        targetBranches = selectedBranchIds.toList();
      } else if (availableBranches.isNotEmpty) {
        targetBranches = availableBranches
            .map((b) => int.tryParse(b['id'].toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }
      if (targetBranches.isEmpty) {
        targetBranches = [1, 22]; // Fallback branch ID if no branches exist
      }

      final body = <String, dynamic>{
        "title": titleController.text.trim(),
        "description": titleController.text.trim(),
        "category": selectedCategoryId.toString(),
        "category_id": selectedCategoryId,
        if (selectedBrandId != null) "brand": selectedBrandId.toString(),
        if (selectedBrandId != null) "brand_id": selectedBrandId,
        "required_quantity": qtyNum.toString(),
        "requested_quantity": qtyNum,
        "quantity": qtyNum,
        "quantity_unit": selectedUnit,
        "unit": selectedUnit,
        "target_price": amountNum.toString(),
        "requested_amount": amountNum,
        "price": amountNum,
        "amount_unit": selectedAmountUnit,
        "required_bag_count": bagCount.toString(),
        "requested_bag_count": bagCount,
        "bag_count": bagCount,
        if (packingKg != null) "packing_weight_kg": packingKg.toString(),
        "expiry_days": "7",
        "target_branches": targetBranches,
        "branches": targetBranches,
        "visible_branches": targetBranches,
        "target_branch_ids": targetBranches,
      };

      print("📤 SUBMITTING REQUIREMENT PAYLOAD: $body");

      await BuyerServices.createOffer(body);
      
      // Refresh offers controllers and dashboard
      try {
        if (Get.isRegistered<BuyerOffersController>(tag: 'requirements')) {
          Get.find<BuyerOffersController>(tag: 'requirements').fetchOffers();
        }
        if (Get.isRegistered<BuyerOffersController>(tag: 'all')) {
          Get.find<BuyerOffersController>(tag: 'all').fetchOffers();
        }
        if (Get.isRegistered<BuyerDashboardController>()) {
          Get.find<BuyerDashboardController>().fetchDashboardData();
        }
      } catch (_) {}

      Get.back();
      Get.snackbar("Success", "Requirement posted successfully",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Notice", e.toString().replaceAll("Exception: ", ""),
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isPosting = false);
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
                    onChanged: _onCategoryChanged,
                    icon: IconlyLight.category,
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown<int>(
                    hint: brands.isEmpty ? "Select Brand (Optional)" : "Select Brand",
                    value: selectedBrandId,
                    items: brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.brandName))).toList(),
                    onChanged: brands.isEmpty ? null : (val) => setState(() => selectedBrandId = val),
                    icon: IconlyLight.info_square,
                  ),
                  const SizedBox(height: 16),

                  if (availableBranches.isNotEmpty) ...[
                    Text("Target Branches", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableBranches.map((b) {
                        final id = int.tryParse(b['id'].toString()) ?? 0;
                        final name = b['location_name'] ?? b['branch_name'] ?? b['city'] ?? "Branch $id";
                        final isSelected = selectedBranchIds.contains(id);
                        return FilterChip(
                          label: Text(name),
                          selected: isSelected,
                          selectedColor: primaryColor.withOpacity(0.25),
                          checkmarkColor: primaryColor,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedBranchIds.add(id);
                              } else {
                                selectedBranchIds.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                      onPressed: isPosting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isPosting 
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
