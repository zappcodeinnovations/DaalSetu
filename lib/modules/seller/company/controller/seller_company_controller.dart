import '../model/seller_company_model.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SellerCompanyController extends GetxController {
  var isLoading = true.obs;
  var companies = <SellerCompanyModel>[].obs;

  var isEditing = false.obs;
  int? currentCompanyId;

  // Form Controllers
  final legalNameController = TextEditingController();
  final companyTypeController = TextEditingController();
  final yearController = TextEditingController();
  final panController = TextEditingController();
  final gstController = TextEditingController();
  final address1Controller = TextEditingController();
  final address2Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final countryController = TextEditingController(text: "India");

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    try {
      isLoading(true);
      final data = await SellerServices.getCompanies();
      companies.assignAll(data);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  void populateFields(SellerCompanyModel company) {
    isEditing.value = true;
    currentCompanyId = company.id;
    legalNameController.text = company.legalName;
    companyTypeController.text = company.companyType;
    yearController.text = company.yearOfEstablishment.toString();
    panController.text = company.panNumber;
    gstController.text = company.gstNumber;
    address1Controller.text = company.addressLine1;
    address2Controller.text = company.addressLine2;
    cityController.text = company.city;
    stateController.text = company.state;
    pincodeController.text = company.pincode;
    countryController.text = company.country;
  }

  Future<void> saveCompany() async {
    if (!_validateFields()) return;

    if (isEditing.value) {
      await updateCompany();
    } else {
      await createCompany();
    }
  }

  bool _validateFields() {
    final pan = panController.text.trim();
    final gst = gstController.text.trim();

    // PAN Validation
    if (pan.length != 10) {
      Get.snackbar("Validation Error", "PAN number must be exactly 10 characters.");
      return false;
    }
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(pan)) {
      Get.snackbar("Validation Error", "Invalid PAN format. Use 5 letters + 4 digits + 1 letter (e.g., ABCDE1234F).");
      return false;
    }

    // GST Validation
    if (gst.length != 15) {
      Get.snackbar("Validation Error", "GST number must be exactly 15 characters.");
      return false;
    }
    // GST format: 2 digits + PAN(10) + 1 digit + Z + 1 alphanumeric
    final gstRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[0-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstRegex.hasMatch(gst)) {
      Get.snackbar("Validation Error", "Invalid GST format. Use: 2 digits + PAN(10) + 1 digit + Z + 1 alphanumeric (e.g., 27ABCDE1234F1Z5).");
      return false;
    }

    if (legalNameController.text.isEmpty || cityController.text.isEmpty || stateController.text.isEmpty) {
      Get.snackbar("Validation Error", "Please fill all required fields.");
      return false;
    }

    return true;
  }

  Future<void> createCompany() async {
    try {
      isLoading(true);
      final Map<String, dynamic> body = _buildRequestBody();

      final newCompany = await SellerServices.createCompany(body);
      
      await fetchCompanyDetails(newCompany.id);
      
      Get.back(); 
      Get.snackbar("Success", "Company created successfully");
      fetchCompanies(); 
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateCompany() async {
    if (currentCompanyId == null) return;
    try {
      isLoading(true);
      final Map<String, dynamic> body = _buildRequestBody();

      await SellerServices.updateCompany(currentCompanyId!, body);
      
      Get.back(); 
      Get.snackbar("Success", "Company updated successfully");
      fetchCompanies(); 
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  /// Offers and challans keep working; they just lose their company link (server sets it to null).
  Future<void> deleteCompany(SellerCompanyModel company) async {
    final ok = await SellerUi.confirm(
      "Delete Company",
      "Delete \"${company.legalName}\"?${company.isPrimary ? ' Another company will become primary.' : ''}",
      confirmText: "Delete",
      color: Colors.red,
    );
    if (!ok) return;
    final result = await SellerUi.run(() => SellerServices.deleteCompany(company.id), successMessage: "Company deleted");
    if (result != null) fetchCompanies();
  }

  Future<void> setPrimaryCompany(int id) async {
    try {
      isLoading(true);
      await SellerServices.setPrimaryCompany(id);
      Get.snackbar("Success", "Company set as primary");
      fetchCompanies();
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Map<String, dynamic> _buildRequestBody() {
    return {
      "legal_name": legalNameController.text.trim(),
      "company_type": companyTypeController.text.trim(),
      "year_of_establishment": int.tryParse(yearController.text.trim()) ?? 0,
      "pan_number": panController.text.trim(),
      "gst_number": gstController.text.trim(),
      "address_line_1": address1Controller.text.trim(),
      "address_line_2": address2Controller.text.trim(),
      "city": cityController.text.trim(),
      "state": stateController.text.trim(),
      "pincode": pincodeController.text.trim(),
      "country": countryController.text.trim(),
    };
  }

  Future<void> fetchCompanyDetails(int id) async {
    try {
      final details = await SellerServices.getCompanyById(id);
      print("Company Details: ${details.legalName}");
    } catch (e) {
      print("Error fetching details: $e");
    }
  }

  void clearForm() {
    isEditing.value = false;
    currentCompanyId = null;
    legalNameController.clear();
    companyTypeController.clear();
    yearController.clear();
    panController.clear();
    gstController.clear();
    address1Controller.clear();
    address2Controller.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    countryController.text = "India";
  }

  @override
  void onClose() {
    legalNameController.dispose();
    companyTypeController.dispose();
    yearController.dispose();
    panController.dispose();
    gstController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    countryController.dispose();
    super.onClose();
  }
}
