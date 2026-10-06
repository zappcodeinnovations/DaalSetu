import '../../categories/model/seller_category_model.dart';
import '../../company/model/seller_company_model.dart';
import '../../branches/model/seller_branch_model.dart';
import '../model/seller_product_model.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerProductController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var products = <SellerProductModel>[].obs;

  // For Add Product (same fields as the web "Create Offer" form)
  var categories = <CategoryTreeModel>[].obs;
  var brands = <BrandModel>[].obs;
  var companies = <SellerCompanyModel>[].obs;
  var branches = <SellerBranchModel>[].obs;
  var selectedCategoryId = Rxn<int>();
  var selectedBrandId = Rxn<int>();
  var selectedCompanyId = Rxn<int>();
  var selectedBranchIds = <int>{}.obs;
  var amountUnit = 'qtl'.obs;
  var loadingFrom = Rxn<DateTime>();
  var loadingTo = Rxn<DateTime>();
  var dealExpiry = Rxn<DateTime>();

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final amountController = TextEditingController();
  final quantityController = TextEditingController();
  final bagCountController = TextEditingController();
  final packingWeightController = TextEditingController();
  final locationController = TextEditingController();
  final remarkController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchSupportData();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading(true);
      final data = await SellerServices.getProducts();
      products.assignAll(data.map((e) => SellerProductModel.fromJson(e)).toList());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchSupportData() async {
    try {
      final catData = await SellerServices.getCategoriesTree();
      categories.assignAll(catData.map((e) => CategoryTreeModel.fromJson(e)).toList());

      final brandData = await SellerServices.getBrandsDropdown();
      brands.assignAll(brandData.map((e) => BrandModel.fromJson(e)).toList());
    } catch (e) {
      debugPrint("Error fetching support data: $e");
    }
    try {
      companies.assignAll(await SellerServices.getCompanies());
      if (selectedCompanyId.value == null && companies.isNotEmpty) {
        selectedCompanyId.value = companies.firstWhere((c) => c.isPrimary, orElse: () => companies.first).id;
      }
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
    try {
      final res = await SellerServices.getSellerBranches();
      final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : const {};
      branches.assignAll((data['my_branches'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SellerBranchModel.fromJson)
          .where((b) => b.id != null));
      // Default: visible in every branch the seller belongs to (backend default too).
      if (selectedBranchIds.isEmpty) selectedBranchIds.addAll(branches.map((b) => b.id!));
    } catch (e) {
      debugPrint("Error fetching branches: $e");
    }
  }

  String _ymd(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String? _validate() {
    if (titleController.text.trim().isEmpty) return "Offer title is required.";
    if (selectedCategoryId.value == null) return "Please select a category.";
    if (amountController.text.trim().isEmpty) return "Price is required.";
    final hasBags = bagCountController.text.trim().isNotEmpty;
    if (hasBags && packingWeightController.text.trim().isEmpty) return "Packing weight is required with bags.";
    if (!hasBags && quantityController.text.trim().isEmpty) return "Enter bags with packing weight, or the quantity.";
    if (loadingFrom.value == null || loadingTo.value == null) return "Loading from and to dates are required.";
    if (loadingTo.value!.isBefore(loadingFrom.value!)) return "Loading to cannot be before loading from.";
    if (dealExpiry.value == null) return "Deal expiry is required.";
    if (branches.isNotEmpty && selectedBranchIds.isEmpty) return "Select at least one branch.";
    return null;
  }

  /// Creates the offer through /api/offers/create/ (same rules as the web form).
  Future<void> createProduct() async {
    final error = _validate();
    if (error != null) {
      SellerUi.error(error);
      return;
    }
    final expiry = dealExpiry.value!;
    final body = <String, dynamic>{
      "title": titleController.text.trim(),
      "description": descController.text.trim(),
      "category_id": selectedCategoryId.value,
      if (selectedBrandId.value != null) "brand_id": selectedBrandId.value,
      "amount": amountController.text.trim(),
      "amount_unit": amountUnit.value,
      if (bagCountController.text.trim().isNotEmpty) ...{
        "bag_count": bagCountController.text.trim(),
        "packing_weight_kg": packingWeightController.text.trim(),
      } else
        "quantity": quantityController.text.trim(),
      "loading_from": _ymd(loadingFrom.value!),
      "loading_to": _ymd(loadingTo.value!),
      "loading_location": locationController.text.trim(),
      "deal_expiry_datetime": "${_ymd(expiry)}T${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}",
      "remark": remarkController.text.trim(),
      if (selectedCompanyId.value != null) "seller_company_id": selectedCompanyId.value,
      if (selectedBranchIds.isNotEmpty) "visible_branch_ids": selectedBranchIds.toList(),
    };

    try {
      isSaving(true);
      final result = await SellerServices.createOffer(body);
      Get.back();
      SellerUi.success(result['message']?.toString() ?? "Offer created successfully");
      fetchProducts();
      clearForm();
    } catch (e) {
      SellerUi.error(e);
    } finally {
      isSaving(false);
    }
  }

  Future<void> toggleOffer(SellerProductModel product) async {
    final activate = !product.isActive;
    final confirmed = await SellerUi.confirm(
      activate ? "Activate Offer" : "Deactivate Offer",
      activate ? "Buyers will be able to see this offer again." : "Buyers will no longer see this offer.",
      confirmText: activate ? "Activate" : "Deactivate",
    );
    if (!confirmed) return;
    final result = await SellerUi.run(() => SellerServices.toggleOfferStatus(product.id, activate));
    if (result != null) fetchProducts();
  }

  Future<void> deleteOffer(SellerProductModel product) async {
    final confirmed = await SellerUi.confirm(
      "Delete Offer",
      "Delete \"${product.title}\" permanently? This cannot be undone.",
      confirmText: "Delete",
      color: Colors.red,
    );
    if (!confirmed) return;
    final result = await SellerUi.run(() => SellerServices.deleteOffer(product.id));
    if (result != null) products.removeWhere((item) => item.id == product.id);
  }

  void clearForm() {
    for (final c in [
      titleController, descController, amountController, quantityController,
      bagCountController, packingWeightController, locationController, remarkController,
    ]) {
      c.clear();
    }
    selectedCategoryId.value = null;
    selectedBrandId.value = null;
    amountUnit.value = 'qtl';
    loadingFrom.value = null;
    loadingTo.value = null;
    dealExpiry.value = null;
  }

  @override
  void onClose() {
    for (final c in [
      titleController, descController, amountController, quantityController,
      bagCountController, packingWeightController, locationController, remarkController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
