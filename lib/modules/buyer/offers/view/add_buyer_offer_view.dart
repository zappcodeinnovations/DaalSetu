import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../services/buyer_services.dart';
import '../../../../services/seller_services.dart';
import '../../../../services/product_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../products/model/offer_option_model.dart';
import '../../../seller/categories/model/seller_category_model.dart';
import '../controller/buyer_offers_controller.dart';
import '../../dashboard/controller/buyer_dashboard_controller.dart';
import '../../../../services/realtime_notification_service.dart';
import 'package:daalsetu/widgets/app_shell.dart';

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
  String selectedAmountUnit = "qtl";

  List<OfferOption> categories = [];
  List<BrandModel> brands = [];
  List<Map<String, dynamic>> availableBranches = [];
  final Set<int> selectedBranchIds = {};
  bool isLoading = true;
  bool isPosting = false;

  @override
  void initState() {
    super.initState();
    quantityController.addListener(_calculateBags);
    packingController.addListener(_calculateBags);
    _loadSupportData();
  }

  @override
  void dispose() {
    quantityController.removeListener(_calculateBags);
    packingController.removeListener(_calculateBags);
    titleController.dispose();
    quantityController.dispose();
    amountController.dispose();
    bagCountController.dispose();
    packingController.dispose();
    super.dispose();
  }

  void _calculateBags() {
    final qtyText = quantityController.text.trim();
    final packingText = packingController.text.trim();

    // If either quantity or packing is cleared or empty, reset calculated bags gracefully
    if (qtyText.isEmpty || packingText.isEmpty) {
      if (bagCountController.text.isNotEmpty) {
        bagCountController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      return;
    }

    final qty = double.tryParse(qtyText);
    final packingKg = double.tryParse(packingText);

    if (qty == null || qty <= 0 || packingKg == null || packingKg <= 0) {
      if (bagCountController.text.isNotEmpty) {
        bagCountController.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      return;
    }

    double totalKg = 0;
    switch (selectedUnit.toLowerCase()) {
      case 'qtl':
      case 'quintal':
        totalKg = qty * 100;
        break;
      case 'ton':
      case 'tonne':
        totalKg = qty * 1000;
        break;
      case 'kg':
      default:
        totalKg = qty;
        break;
    }

    final bags = (totalKg / packingKg).round();
    final bagText = bags > 0 ? bags.toString() : '';
    if (bagCountController.text != bagText) {
      bagCountController.value = TextEditingValue(
        text: bagText,
        selection: TextSelection.collapsed(offset: bagText.length),
      );
    }
  }

  Future<void> _loadSupportData() async {
    try {
      List<OfferOption> catOptions = [];

      // 1. Fetch from master parent categories API (/api/categories/parent-dropdown/)
      try {
        final parentCats = await ProductService.getParentCategories();
        if (parentCats.isNotEmpty) {
          catOptions = parentCats
              .where((c) => c.name.trim().isNotEmpty)
              .toList();
        }
      } catch (e) {
        print("⚠️ Master parent categories fetch error: $e");
      }

      // 2. Fallback to categories tree if parent dropdown fails or returns empty
      if (catOptions.isEmpty) {
        try {
          final catData = await SellerServices.getCategoriesTree();
          final parsed = catData.map((e) => CategoryTreeModel.fromJson(e)).toList();
          catOptions = parsed
              .where((c) =>
                  (c.level == 0 || c.parentId == null) &&
                  c.status.toLowerCase() == 'active' &&
                  c.name.trim().isNotEmpty)
              .map((c) => OfferOption(id: c.id, name: c.name))
              .toList();
        } catch (e) {
          print("⚠️ Fallback categories tree fetch error: $e");
        }
      }

      // Load branches with multi-source fallback (seller branches, public branches, default branch)
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

      // If user has no branches assigned via seller endpoint, load public branches
      if (branchList.isEmpty) {
        try {
          final publicBranches = await SellerServices.getPublicBranches();
          if (publicBranches.isNotEmpty) {
            branchList.addAll(publicBranches);
          }
        } catch (e) {
          print("⚠️ Public branches fetch error: $e");
        }
      }

      // Guarantee at least the primary AMR158M / default branch so branches are never empty or non-selectable
      if (branchList.isEmpty) {
        branchList.add({
          'id': 1,
          'branch_code': 'AMR158M',
          'location_name': 'AMR158M',
        });
      }

      final branchIdsToSelect = <int>{};
      for (var b in branchList) {
        if (b['id'] != null) {
          final id = int.tryParse(b['id'].toString());
          if (id != null) branchIdsToSelect.add(id);
        }
      }

      setState(() {
        categories = catOptions;
        availableBranches = branchList;
        selectedBranchIds.clear();
        selectedBranchIds.addAll(branchIdsToSelect);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onCategoryChanged(int? catId) async {
    setState(() {
      selectedCategoryId = catId;
      selectedBrandId = 0; // Default to "Any Brand / Loose"
      brands = [];
    });

    if (catId == null) return;

    try {
      final Map<int, String> brandMap = {};
      final Set<String> normalizedSeen = {};

      void addBrandIfValid(dynamic idRaw, dynamic nameRaw) {
        if (idRaw == null || nameRaw == null) return;
        final id = int.tryParse(idRaw.toString()) ?? 0;
        final name = nameRaw.toString().trim();
        if (id <= 0 || name.isEmpty) return;

        final norm = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (!normalizedSeen.contains(norm)) {
          normalizedSeen.add(norm);
          brandMap[id] = name;
        }
      }

      // 1. Fetch category-specific brands from /api/categories/$catId/brands/
      try {
        final catBrands = await ProductService.getCategoryBrands(catId);
        for (final b in catBrands) {
          addBrandIfValid(b.id, b.name);
        }
      } catch (e) {
        print("⚠️ Category brands fetch error: $e");
      }

      // 2. If endpoint returned empty, resolve brands mapped specifically to this category in categories tree
      if (brandMap.isEmpty) {
        try {
          final catData = await SellerServices.getCategoriesTree();
          void extractCategorySpecificBrands(dynamic node) {
            if (node is Map) {
              final nodeId = int.tryParse(node['id']?.toString() ?? '');
              if (nodeId == catId) {
                if (node['brands'] is List) {
                  for (final b in node['brands']) {
                    if (b is Map) {
                      addBrandIfValid(b['id'], b['brand_name'] ?? b['name']);
                    }
                  }
                }
                // Also check immediate children of this category
                if (node['children'] is List) {
                  for (final child in node['children']) {
                    if (child is Map && child['brands'] is List) {
                      for (final b in child['brands']) {
                        if (b is Map) {
                          addBrandIfValid(b['id'], b['brand_name'] ?? b['name']);
                        }
                      }
                    }
                  }
                }
                return;
              }
              if (node['children'] is List) {
                for (final child in node['children']) {
                  extractCategorySpecificBrands(child);
                }
              }
            }
          }

          for (final root in catData) {
            extractCategorySpecificBrands(root);
          }
        } catch (e) {
          print("⚠️ Category tree brands extraction error: $e");
        }
      }

      // 4. Construct brand models with "Any Brand / Loose" (id 0) at the top, followed by sorted brands
      final List<BrandModel> brandList = [
        BrandModel(id: 0, brandName: "Any Brand / Loose"),
      ];

      final sortedEntries = brandMap.entries.toList()
        ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

      for (final entry in sortedEntries) {
        brandList.add(BrandModel(id: entry.key, brandName: entry.value));
      }

      if (mounted) {
        setState(() {
          brands = brandList;
          selectedBrandId = 0;
        });
      }
    } catch (e) {
      print("⚠️ Preferred brands resolution error: $e");
    }
  }

  Future<void> _submit() async {
    if (titleController.text.trim().isEmpty || selectedCategoryId == null) {
      AppSnackbar.showWarning(
        title: "Required Fields Missing",
        message: "Please enter Requirement Title and select a Category.",
      );
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
        if (selectedBrandId != null && selectedBrandId! > 0)
          "brand": selectedBrandId.toString(),
        if (selectedBrandId != null && selectedBrandId! > 0)
          "brand_id": selectedBrandId,
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
        if (Get.isRegistered<RealtimeNotificationService>()) {
          RealtimeNotificationService.to.refreshNow();
        }
      } catch (_) {}

      Get.back();
      AppSnackbar.showSuccess(
        title: "Success",
        message: "Requirement posted successfully",
      );
    } catch (e) {
      AppSnackbar.showError(
        title: "Notice",
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(leading: const AppBarLeading(), leadingWidth: AppBarLeading.widthFor(context), 
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
                    Text(
                      "Target Branches",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableBranches.map((b) {
                        final id = int.tryParse(b['id'].toString()) ?? 0;
                        final name = b['location_name'] ?? b['branch_name'] ?? b['city'] ?? "Branch $id";
                        final isSelected = selectedBranchIds.contains(id);
                        return FilterChip(
                          label: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.amber.shade200 : Colors.amber.shade900)
                                  : (theme.textTheme.bodyMedium?.color ?? Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          backgroundColor: theme.cardColor,
                          checkmarkColor: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          side: BorderSide(
                            color: isSelected ? primaryColor : theme.dividerColor.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedUnit = val;
                                selectedAmountUnit = val;
                                _calculateBags();
                              });
                            }
                          },
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
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedUnit = val;
                                selectedAmountUnit = val;
                                _calculateBags();
                              });
                            }
                          },
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hintColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : const Color(0xFF475569));
    final iconColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: hintColor,
        ),
        prefixIcon: Icon(icon, size: 20, color: iconColor),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFFFB300),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : const Color(0xFF475569));
    final iconColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          isExpanded: true,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: theme.cardColor,
        ),
      ),
    );
  }
}
