import '../../categories/model/seller_category_model.dart';
import '../../company/model/seller_company_model.dart';
import '../../branches/model/seller_branch_model.dart';
import '../model/seller_product_model.dart';
import '../service/seller_offer_export_service.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_preferences.dart';
import '../../common/seller_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/realtime_notification_service.dart';
import '../../../nav_bar/controller/nav_controller.dart';
import 'package:daalsetu/widgets/offer_image_picker.dart';

class SellerProductController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var products = <SellerProductModel>[].obs;

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
  /// Offer images chosen with multi-select (max 10).
  final selectedImagePaths = <String>[].obs;
  var selectedVideoPath = RxnString();
  var sellerName = 'Seller'.obs;
  var loadingFrom = Rxn<DateTime>();
  var loadingTo = Rxn<DateTime>();
  // Delivery Period offered to buyers (MoM point 8).
  var deliveryFrom = Rxn<DateTime>();
  var deliveryTo = Rxn<DateTime>();
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

    if (quantityController.text.isNotEmpty) {
      _onQuantityChanged();
    } else if (bagCountController.text.isNotEmpty) {
      _onBagsChanged();
    }
  }

  double get _unitMultiplier {
    switch (quantityUnit.value) {
      case 'ton':
        return 1000.0;
      case 'qtl':
        return 100.0;
      case 'kg':
      default:
        return 1.0;
    }
  }

  bool _isCalculating = false;

  void _onBagsChanged() {
    if (_isCalculating) return;
    final bagsStr = bagCountController.text.trim();
    if (bagsStr.isEmpty) return;

    final bags = double.tryParse(bagsStr);
    if (bags == null || bags <= 0) return;

    final qtyStr = quantityController.text.trim();
    final packingStr = packingWeightController.text.trim();

    if (qtyStr.isNotEmpty) {
      // Total quantity is already specified; adjust packing weight to keep total quantity intact.
      final qty = double.tryParse(qtyStr);
      if (qty != null && qty > 0) {
        final quantityInKg = qty * _unitMultiplier;
        final packing = quantityInKg / bags;
        final newPacking = packing
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '');
        if (packingWeightController.text != newPacking) {
          _isCalculating = true;
          packingWeightController.text = newPacking;
          _isCalculating = false;
        }
      }
    } else if (packingStr.isNotEmpty) {
      // Quantity is not yet set; calculate total quantity from bags * packing weight.
      final packing = double.tryParse(packingStr);
      if (packing != null && packing > 0) {
        final quantityInKg = bags * packing;
        final quantity = quantityInKg / _unitMultiplier;
        final newQty = quantity
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '');
        if (quantityController.text != newQty) {
          _isCalculating = true;
          quantityController.text = newQty;
          _isCalculating = false;
        }
      }
    }
  }

  void _onQuantityChanged() {
    if (_isCalculating) return;
    final qtyStr = quantityController.text.trim();
    if (qtyStr.isEmpty) return;

    final qty = double.tryParse(qtyStr);
    if (qty == null || qty <= 0) return;

    final packingStr = packingWeightController.text.trim();
    final packing = double.tryParse(packingStr);
    if (packing != null && packing > 0) {
      final quantityInKg = qty * _unitMultiplier;
      final newBags = (quantityInKg / packing).ceil().toString();
      if (bagCountController.text != newBags) {
        _isCalculating = true;
        bagCountController.text = newBags;
        _isCalculating = false;
      }
    } else {
      final bagsStr = bagCountController.text.trim();
      final bags = double.tryParse(bagsStr);
      if (bags != null && bags > 0) {
        final quantityInKg = qty * _unitMultiplier;
        final newPacking = (quantityInKg / bags)
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '');
        if (packingWeightController.text != newPacking) {
          _isCalculating = true;
          packingWeightController.text = newPacking;
          _isCalculating = false;
        }
      }
    }
  }

  void _onPackingChanged() {
    if (_isCalculating) return;
    final packingStr = packingWeightController.text.trim();
    if (packingStr.isEmpty) return;

    final packing = double.tryParse(packingStr);
    if (packing == null || packing <= 0) return;

    final qtyStr = quantityController.text.trim();
    final bagsStr = bagCountController.text.trim();

    if (qtyStr.isNotEmpty) {
      // Updating weight adjusts number of bags, preserving total quintal quantity.
      final qty = double.tryParse(qtyStr);
      if (qty != null && qty > 0) {
        final quantityInKg = qty * _unitMultiplier;
        final newBags = (quantityInKg / packing).ceil().toString();
        if (bagCountController.text != newBags) {
          _isCalculating = true;
          bagCountController.text = newBags;
          _isCalculating = false;
        }
      }
    } else if (bagsStr.isNotEmpty) {
      // Quantity is not yet set; calculate total quantity from bags * packing weight.
      final bags = double.tryParse(bagsStr);
      if (bags != null && bags > 0) {
        final quantityInKg = bags * packing;
        final quantity = quantityInKg / _unitMultiplier;
        final newQty = quantity
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.00$'), '');
        if (quantityController.text != newQty) {
          _isCalculating = true;
          quantityController.text = newQty;
          _isCalculating = false;
        }
      }
    }
  }

  void attachCalculationListeners() {
    bagCountController.removeListener(_onBagsChanged);
    quantityController.removeListener(_onQuantityChanged);
    packingWeightController.removeListener(_onPackingChanged);

    bagCountController.addListener(_onBagsChanged);
    quantityController.addListener(_onQuantityChanged);
    packingWeightController.addListener(_onPackingChanged);
  }

  @override
  void onInit() {
    super.onInit();
    attachCalculationListeners();

    fetchProducts();
    fetchSupportData();
  }

  bool _fetchInProgress = false;

  Future<void> fetchProducts({bool silent = false}) async {
    // Background refresh runs every 10s; skip it while a request is still open.
    if (_fetchInProgress || isClosed || (silent && isSaving.value)) return;
    _fetchInProgress = true;
    try {
      if (!silent) isLoading(true);
      final data = await SellerServices.getProducts(silent: silent);
      if (isClosed) return;
      products.assignAll(
        data
            .map((e) => SellerProductModel.fromJson(e))
            .where((p) => !p.isBuyerOffer)
            .toList(),
      );
    } catch (e) {
      if (!silent) SellerUi.error(e);
    } finally {
      _fetchInProgress = false;
      if (!silent) isLoading(false);
    }
  }

  /// Generates a professionally formatted Excel workbook and opens the
  /// platform share/save sheet.
  Future<void> exportProducts() async {
    if (products.isEmpty) {
      SellerUi.error('There are no offers available to export.');
      return;
    }

    try {
      await SellerOfferExportService.exportToDownloads(products: products);
      SellerUi.success('Offers Excel saved to Downloads.');
    } catch (error) {
      SellerUi.error(error);
    }
  }

  Future<void> shareProducts() async {
    if (products.isEmpty) {
      SellerUi.error('There are no offers available to share.');
      return;
    }

    try {
      await SellerOfferExportService.share(products: products);
    } catch (error) {
      SellerUi.error(error);
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
        final primary = companies.firstWhere(
          (c) => c.isPrimary,
          orElse: () => companies.first,
        );
        selectedCompanyId.value = primary.id;
        sellerName.value = primary.legalName;
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

  /// Adds images with multi-select, up to 10 in total.
  Future<void> pickOfferImage() async {
    final room = maxOfferImages - selectedImagePaths.length;
    if (room <= 0) {
      SellerUi.error("You can add up to $maxOfferImages images.");
      return;
    }
    final paths = await pickOfferImages(room: room);
    if (paths.isEmpty) return;
    selectedImagePaths.addAll(paths);
    selectedImagePath.value = selectedImagePaths.first;
  }

  void removeOfferImage(String path) {
    selectedImagePaths.remove(path);
    selectedImagePath.value = selectedImagePaths.isEmpty ? null : selectedImagePaths.first;
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
    if (deliveryFrom.value == null || deliveryTo.value == null)
      return "Delivery period (from and to) is required.";
    if (deliveryTo.value!.isBefore(deliveryFrom.value!))
      return "Delivery To cannot be before Delivery From.";
    if (dealExpiry.value == null) return "Deal expiry is required.";
    if (!dealExpiry.value!.isAfter(DateTime.now())) {
      return "Deal expiry time must be in the future.";
    }
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
      "delivery_from": _ymd(deliveryFrom.value!),
      "delivery_to": _ymd(deliveryTo.value!),
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
      final imagesToUpload = selectedImagePaths.toList();
      final videoToUpload = selectedVideoPath.value;

      final result = await SellerServices.createOffer(
        body,
        imagePaths: imagesToUpload,
        videoPath: videoToUpload,
      );
      // /api/offers/create/ returns the new offer under "product".
      final data = result['product'] ?? result['data'];
      final productId = data is Map ? int.tryParse('${data['id']}') : null;
      var mediaFailed = false;

      // Resilient fallback: If the backend did not attach media during offer creation,
      // upload via dedicated endpoints.
      if (productId != null) {
        final existingImages = (data is Map && data['images'] is List)
            ? (data['images'] as List)
            : [];
        final existingVideos =
            (data is Map &&
                (data['product_videos'] is List || data['videos'] is List))
            ? ((data['product_videos'] ?? data['videos']) as List)
            : [];

        if (imagesToUpload.isNotEmpty && existingImages.isEmpty) {
          for (var i = 0; i < imagesToUpload.length; i++) {
            try {
              await SellerServices.uploadProductImage(productId, imagesToUpload[i], isPrimary: i == 0);
            } catch (_) {
              mediaFailed = true;
            }
          }
        }
        if (videoToUpload != null && existingVideos.isEmpty) {
          try {
            await SellerServices.uploadProductVideo(
              productId,
              videoToUpload,
              'Offer Video',
            );
          } catch (_) {
            mediaFailed = true;
          }
        }
      }
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().changeIndex(1);
      }
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.sellerProducts ||
            route.settings.name == AppRoutes.mainNav ||
            route.isFirst,
      );
      SellerUi.success(
        mediaFailed
            ? "Offer created, but one or more media files could not be uploaded."
            : result['message']?.toString() ?? "Offer created successfully",
      );
      fetchProducts();
      clearForm();
      if (Get.isRegistered<RealtimeNotificationService>()) {
        RealtimeNotificationService.to.refreshNow();
      }
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
    if (result != null) {
      // Optimistically update the item in the reactive list for instant UI feedback
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        final current = products[index];
        products[index] = SellerProductModel(
          id: current.id,
          title: current.title,
          description: current.description,
          categoryId: current.categoryId,
          categoryName: current.categoryName,
          brandName: current.brandName,
          amount: current.amount,
          unit: current.unit,
          status: activate ? 'active' : 'inactive',
          isActive: activate,
          isExpired: current.isExpired,
          interestCount: current.interestCount,
          bagCount: current.bagCount,
          packingWeight: current.packingWeight,
          loadingLocation: current.loadingLocation,
          imageUrls: current.imageUrls,
          videoUrls: current.videoUrls,
          createdAt: current.createdAt,
          isBuyerOffer: current.isBuyerOffer,
        );
      }
      fetchProducts();
    }
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
    brands.clear();
    amountUnit.value = 'qtl';
    quantityUnit.value = 'qtl';
    packingWeightController.text = '30';
    selectedImagePath.value = null;
    selectedImagePaths.clear();
    selectedVideoPath.value = null;
    loadingFrom.value = null;
    loadingTo.value = null;
    deliveryFrom.value = null;
    deliveryTo.value = null;
    dealExpiry.value = null;
    selectedBranchIds.clear();
    if (branches.isNotEmpty) {
      selectedBranchIds.addAll(branches.map((b) => b.id!));
    }
  }

  @override
  void onClose() {
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
