import '../../categories/model/seller_category_model.dart';
import '../../company/model/seller_company_model.dart';
import '../../branches/model/seller_branch_model.dart';
import '../model/seller_product_model.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_preferences.dart';
import '../../common/seller_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class SellerProductController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var products = <SellerProductModel>[].obs;
  Timer? _refreshTimer;

  // For Add Product (same fields as the web "Create Offer" form)
  var categories = <CategoryTreeModel>[].obs;
  var categoryLabels = <int, String>{}.obs;
  var brands = <BrandModel>[].obs;
  var isBrandsLoading = false.obs;
  var companies = <SellerCompanyModel>[].obs;
  var branches = <SellerBranchModel>[].obs;
  var selectedCategoryId = Rxn<int>();
  var selectedBrandId = Rxn<int>();
  var selectedCompanyId = Rxn<int>();
  var selectedBranchIds = <int>{}.obs;
  var amountUnit = 'qtl'.obs;
  var quantityUnit = 'qtl'.obs;
  var selectedImagePath = RxnString();
  var selectedVideoPath = RxnString();
  var sellerName = 'Seller'.obs;
  var loadingFrom = Rxn<DateTime>();
  var loadingTo = Rxn<DateTime>();
  var dealExpiry = Rxn<DateTime>();

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final amountController = TextEditingController();
  final quantityController = TextEditingController();
  final bagCountController = TextEditingController();
  final packingWeightController = TextEditingController(text: '30');
  final locationController = TextEditingController();
  final remarkController = TextEditingController();

  /// An offer's rate and quantity must use the same unit (KG/QTL/TON).
  void setOfferUnit(String? value) {
    final unit = value ?? 'qtl';
    amountUnit.value = unit;
    quantityUnit.value = unit;
  }

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchSupportData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchProducts(silent: true));
  }

  Future<void> fetchProducts({bool silent = false}) async {
    try {
      if (!silent) isLoading(true);
      final data = await SellerServices.getProducts();
      products.assignAll(
        data.map((e) => SellerProductModel.fromJson(e)).toList(),
      );
    } catch (e) {
      if (!silent) Get.snackbar("Error", e.toString());
    } finally {
      if (!silent) isLoading(false);
    }
  }

  Future<void> fetchSupportData() async {
    sellerName.value = await AppPreferences.getUsername() ?? 'Seller';
    try {
      final catData = await SellerServices.getCategoriesTree();
      final roots = catData.map((e) => CategoryTreeModel.fromJson(e)).toList();
      final flat = <CategoryTreeModel>[];
      final labels = <int, String>{};
      void addNodes(List<CategoryTreeModel> nodes, String parentPath) {
        for (final node in nodes) {
          final path = parentPath.isEmpty
              ? node.name
              : '$parentPath > ${node.name}';
          flat.add(node);
          labels[node.id] = path;
          addNodes(node.children, path);
        }
      }

      addNodes(roots, '');
      categories.assignAll(flat);
      categoryLabels.assignAll(labels);
    } catch (e) {
      debugPrint("Error fetching support data: $e");
    }
    try {
      companies.assignAll(await SellerServices.getCompanies());
      if (selectedCompanyId.value == null && companies.isNotEmpty) {
        selectedCompanyId.value = companies
            .firstWhere((c) => c.isPrimary, orElse: () => companies.first)
            .id;
      }
    } catch (e) {
      debugPrint("Error fetching companies: $e");
    }
    try {
      final res = await SellerServices.getSellerBranches();
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : const {};
      branches.assignAll(
        (data['my_branches'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SellerBranchModel.fromJson)
            .where((b) => b.id != null),
      );
      // Default: visible in every branch the seller belongs to (backend default too).
      if (selectedBranchIds.isEmpty)
        selectedBranchIds.addAll(branches.map((b) => b.id!));
    } catch (e) {
      debugPrint("Error fetching branches: $e");
    }
  }

  String categoryLabel(CategoryTreeModel category) =>
      categoryLabels[category.id] ?? category.name;

  Future<void> selectCategory(int? categoryId) async {
    selectedCategoryId.value = categoryId;
    selectedBrandId.value = null;
    brands.clear();
    if (categoryId == null) return;

    try {
      isBrandsLoading(true);
      final brandData = await SellerServices.getCategoryBrands(categoryId);
      brands.assignAll(
        brandData
            .whereType<Map>()
            .map((item) => BrandModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    } catch (e) {
      debugPrint("Error fetching category brands: $e");
      SellerUi.error("Unable to load brands for the selected category.");
    } finally {
      isBrandsLoading(false);
    }
  }

  Future<void> pickOfferImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image != null) selectedImagePath.value = image.path;
  }

  Future<void> pickOfferVideo() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) selectedVideoPath.value = video.path;
  }

  String fileName(String? path) {
    if (path == null || path.isEmpty) return '';
    return path.split(RegExp(r'[\\/]')).last;
  }

  String _ymd(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String? _validate() {
    if (titleController.text.trim().isEmpty) return "Offer title is required.";
    if (selectedCategoryId.value == null) return "Please select a category.";
    if (amountController.text.trim().isEmpty) return "Price is required.";
    final hasBags = bagCountController.text.trim().isNotEmpty;
    if (hasBags && packingWeightController.text.trim().isEmpty)
      return "Packing weight is required with bags.";
    if (!hasBags && quantityController.text.trim().isEmpty)
      return "Enter bags with packing weight, or the quantity.";
    if (loadingFrom.value == null || loadingTo.value == null)
      return "Loading from and to dates are required.";
    if (loadingTo.value!.isBefore(loadingFrom.value!))
      return "Loading to cannot be before loading from.";
    if (dealExpiry.value == null) return "Deal expiry is required.";
    if (branches.isNotEmpty && selectedBranchIds.isEmpty)
      return "Select at least one branch.";
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
      "quantity_unit": quantityUnit.value,
      if (bagCountController.text.trim().isNotEmpty) ...{
        "bag_count": bagCountController.text.trim(),
        "packing_weight_kg": packingWeightController.text.trim(),
      } else
        "quantity": quantityController.text.trim(),
      "loading_from": _ymd(loadingFrom.value!),
      "loading_to": _ymd(loadingTo.value!),
      "loading_location": locationController.text.trim(),
      "deal_expiry_datetime":
          "${_ymd(expiry)}T${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}",
      "remark": remarkController.text.trim(),
      if (selectedCompanyId.value != null)
        "seller_company_id": selectedCompanyId.value,
      if (selectedBranchIds.isNotEmpty)
        "visible_branch_ids": selectedBranchIds.toList(),
    };

    try {
      isSaving(true);
      final result = await SellerServices.createOffer(body);
      // /api/offers/create/ returns the new offer under "product".
      final data = result['product'] ?? result['data'];
      final productId = data is Map ? int.tryParse('${data['id']}') : null;
      var mediaFailed = false;
      if (productId != null && selectedImagePath.value != null) {
        try {
          await SellerServices.uploadProductImage(
            productId,
            selectedImagePath.value!,
          );
        } catch (_) {
          mediaFailed = true;
        }
      }
      if (productId != null && selectedVideoPath.value != null) {
        try {
          await SellerServices.uploadProductVideo(
            productId,
            selectedVideoPath.value!,
            'Offer Video',
          );
        } catch (_) {
          mediaFailed = true;
        }
      }
      Get.back();
      SellerUi.success(
        mediaFailed
            ? "Offer created, but one or more media files could not be uploaded."
            : result['message']?.toString() ?? "Offer created successfully",
      );
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
      activate
          ? "Buyers will be able to see this offer again."
          : "Buyers will no longer see this offer.",
      confirmText: activate ? "Activate" : "Deactivate",
    );
    if (!confirmed) return;
    final result = await SellerUi.run(
      () => SellerServices.toggleOfferStatus(product.id, activate),
    );
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
    final result = await SellerUi.run(
      () => SellerServices.deleteOffer(product.id),
    );
    if (result != null) products.removeWhere((item) => item.id == product.id);
  }

  void clearForm() {
    for (final c in [
      titleController,
      descController,
      amountController,
      quantityController,
      bagCountController,
      packingWeightController,
      locationController,
      remarkController,
    ]) {
      c.clear();
    }
    selectedCategoryId.value = null;
    selectedBrandId.value = null;
    amountUnit.value = 'qtl';
    quantityUnit.value = 'qtl';
    packingWeightController.text = '30';
    selectedImagePath.value = null;
    selectedVideoPath.value = null;
    loadingFrom.value = null;
    loadingTo.value = null;
    dealExpiry.value = null;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    for (final c in [
      titleController,
      descController,
      amountController,
      quantityController,
      bagCountController,
      packingWeightController,
      locationController,
      remarkController,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
