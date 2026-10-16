import '../model/seller_company_model.dart';
import '../../../../services/seller_services.dart';
import '../../common/seller_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daalsetu/utils/tax_id_formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../../network/api_client.dart';

class SellerCompanyController extends GetxController {
  var isLoading = true.obs;
  var companies = <SellerCompanyModel>[].obs;

  var isEditing = false.obs;
  int? currentCompanyId;
  final errors = <String, String>{}.obs;

  void clearError(String field) => errors.remove(field);

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

  bool validateFields() => _validateFields();

  void _applyServerFieldErrors(Map<String, String> fieldErrors) {
    const aliases = <String, String>{
      'pan': 'pan_number',
      'gst': 'gst_number',
      'year': 'year_of_establishment',
      'address': 'address_line_1',
    };
    for (final entry in fieldErrors.entries) {
      errors[aliases[entry.key] ?? entry.key] = entry.value;
    }
  }

  bool _validateFields() {
    errors.clear();

    final legalName = legalNameController.text.trim();
    if (legalName.isEmpty) {
      errors['legal_name'] = "Please enter Legal Name.";
    }

    final yearText = yearController.text.trim();
    final year = int.tryParse(yearText);
    final currentYear = DateTime.now().year;
    if (yearText.isEmpty) {
      errors['year_of_establishment'] =
          "Please enter Year of Establishment.";
    } else if (year == null || year < 1800 || year > currentYear) {
      errors['year_of_establishment'] =
          "Year must be between 1800 and $currentYear.";
    }

    final pan = panController.text.trim().toUpperCase();
    panController.text = pan;
    final panError = TaxIdValidator.pan(pan, required: true);
    if (panError != null) {
      errors['pan_number'] = panError;
    }

    final gst = gstController.text.trim().toUpperCase();
    gstController.text = gst;
    final gstError = TaxIdValidator.gst(gst, required: true);
    if (gstError != null) {
      errors['gst_number'] = gstError;
    } else {
      final gstPanError = TaxIdValidator.gstMatchesPan(pan, gst);
      if (gstPanError != null) {
        errors['gst_number'] = gstPanError;
      }
    }

    if (address1Controller.text.trim().isEmpty) {
      errors['address_line_1'] = "Please enter Address Line 1.";
    }

    final pincode = pincodeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      errors['pincode'] = pincode.isEmpty
          ? "Please enter Pincode."
          : "Pincode must be exactly 6 digits.";
    }

    if (cityController.text.trim().isEmpty) {
      errors['city'] = "Please select City.";
    }

    if (stateController.text.trim().isEmpty) {
      errors['state'] = "Please select State.";
    }

    if (countryController.text.trim().isEmpty) {
      errors['country'] = "Please enter Country.";
    }

    if (errors.isNotEmpty) {
      if (!Get.testMode && Get.context != null) {
        AppSnackbar.showError(
          title: "Validation Error",
          message: errors.values.first,
        );
      }
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

      Get.until((route) =>
          route.settings.name == AppRoutes.sellerCompany ||
          route.settings.name == AppRoutes.mainNav ||
          route.isFirst);
      AppSnackbar.showSuccess(message: "Company created successfully");
      fetchCompanies();
    } catch (e) {
      if (e is ApiRequestException && e.fieldErrors != null) {
        _applyServerFieldErrors(e.fieldErrors!);
      }
      AppSnackbar.showError(
        message: ApiClient.userFriendlyErrorMessage(e.toString()),
      );
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

      Get.until((route) =>
          route.settings.name == AppRoutes.sellerCompany ||
          route.settings.name == AppRoutes.mainNav ||
          route.isFirst);
      AppSnackbar.showSuccess(message: "Company updated successfully");
      fetchCompanies();
    } catch (e) {
      if (e is ApiRequestException && e.fieldErrors != null) {
        _applyServerFieldErrors(e.fieldErrors!);
      }
      AppSnackbar.showError(
        message: ApiClient.userFriendlyErrorMessage(e.toString()),
      );
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
    final result = await SellerUi.run(
      () => SellerServices.deleteCompany(company.id),
      successMessage: "Company deleted",
    );
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
      "pan_number": panController.text.trim().toUpperCase(),
      "gst_number": gstController.text.trim().toUpperCase(),
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
    errors.clear();
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
