import '../../categories/model/seller_category_model.dart';
import '../model/seller_product_model.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerProductController extends GetxController {
  var isLoading = true.obs;
  var products = <SellerProductModel>[].obs;

  // For Add Product
  var categories = <CategoryTreeModel>[].obs;
  var brands = <BrandModel>[].obs;
  var selectedCategoryId = Rxn<int>();
  var selectedBrandId = Rxn<int>();

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final amountController = TextEditingController();
  final unitController = TextEditingController(text: "qtl");
  final bagCountController = TextEditingController();
  final packingWeightController = TextEditingController();
  final locationController = TextEditingController();

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
      print("Error fetching support data: $e");
    }
  }

  Future<void> createProduct() async {
    if (titleController.text.isEmpty || selectedCategoryId.value == null) {
      Get.snackbar("Error", "Please fill required fields");
      return;
    }

    try {
      isLoading(true);
      final Map<String, dynamic> body = {
        "title": titleController.text.trim(),
        "description": descController.text.trim(),
        "category": selectedCategoryId.value,
        "brand": selectedBrandId.value,
        "amount": amountController.text.trim(),
        "unit": unitController.text.trim(),
        "bag_count": int.tryParse(bagCountController.text.trim()) ?? 0,
        "packing_weight_kg": packingWeightController.text.trim(),
        "loading_location": locationController.text.trim(),
        "status": "active",
      };

      await SellerServices.createProduct(body);
      Get.back();
      Get.snackbar("Success", "Product listed successfully");
      fetchProducts();
      clearForm();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
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
    titleController.clear();
    descController.clear();
    amountController.clear();
    bagCountController.clear();
    packingWeightController.clear();
    locationController.clear();
    selectedCategoryId.value = null;
    selectedBrandId.value = null;
  }

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    amountController.dispose();
    unitController.dispose();
    bagCountController.dispose();
    packingWeightController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
