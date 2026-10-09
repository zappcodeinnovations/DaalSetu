import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../utils/tax_id_formatters.dart';
import '../controller/transporter_company_controller.dart';
import '../model/company_model.dart';
import '../../../../routes/app_routes.dart';

class TransporterCompanyForm extends StatefulWidget {
  final CompanyModel? company; // Null for create, provided for edit

  const TransporterCompanyForm({super.key, this.company});

  @override
  State<TransporterCompanyForm> createState() => _TransporterCompanyFormState();
}

class _TransporterCompanyFormState extends State<TransporterCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  final TransporterCompanyController controller =
      Get.find<TransporterCompanyController>();

  bool _isSubmitting = false;

  late TextEditingController _legalNameCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _employeesCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _panCtrl;
  late TextEditingController _address1Ctrl;
  late TextEditingController _address2Ctrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _landmarkCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _legalNameCtrl = TextEditingController(text: c?.legalName ?? '');
    _typeCtrl = TextEditingController(text: c?.companyType ?? '');
    _yearCtrl = TextEditingController(
      text: c?.yearOfEstablishment?.toString() ?? '',
    );
    _employeesCtrl = TextEditingController(
      text: c?.numberOfEmployees?.toString() ?? '',
    );
    _gstCtrl = TextEditingController(text: c?.gstNumber ?? '');
    _panCtrl = TextEditingController(text: c?.panNumber ?? '');
    _address1Ctrl = TextEditingController(text: c?.addressLine1 ?? '');
    _address2Ctrl = TextEditingController(text: c?.addressLine2 ?? '');
    _cityCtrl = TextEditingController(text: c?.city ?? '');
    _stateCtrl = TextEditingController(text: c?.state ?? '');
    _pincodeCtrl = TextEditingController(text: c?.pincode ?? '');
    _countryCtrl = TextEditingController(text: c?.country ?? 'India');
    _landmarkCtrl = TextEditingController(text: c?.landmark ?? '');
  }

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _typeCtrl.dispose();
    _yearCtrl.dispose();
    _employeesCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _countryCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final gstPanError = TaxIdValidator.gstMatchesPan(
      _panCtrl.text,
      _gstCtrl.text,
    );
    if (gstPanError != null) {
      Get.snackbar('Validation error', gstPanError);
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      "legal_name": _legalNameCtrl.text.trim(),
      "company_type": _typeCtrl.text.trim(),
      "year_of_establishment": int.tryParse(_yearCtrl.text.trim()),
      "number_of_employees": int.tryParse(_employeesCtrl.text.trim()),
      "gst_number": _gstCtrl.text.trim().toUpperCase(),
      "pan_number": _panCtrl.text.trim().toUpperCase(),
      "address_line_1": _address1Ctrl.text.trim(),
      "address_line_2": _address2Ctrl.text.trim(),
      "state": _stateCtrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "pincode": _pincodeCtrl.text.trim(),
      "country": _countryCtrl.text.trim(),
      "landmark": _landmarkCtrl.text.trim(),
    };

    bool success;
    if (widget.company == null) {
      success = await controller.createCompany(data);
    } else {
      success = await controller.updateCompany(widget.company!.id, data);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      Get.until((route) => route.settings.name == AppRoutes.transporterCompany || route.settings.name == AppRoutes.mainNav || route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.company != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEdit ? "Edit Company" : "Register Company",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle("Basic Details"),
                _buildTextField(
                  label: "Legal Name",
                  controller: _legalNameCtrl,
                  isRequired: true,
                ),
                _buildTextField(
                  label: "Company Type (e.g. Private Limited)",
                  controller: _typeCtrl,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: "Est. Year",
                        controller: _yearCtrl,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: "Employees",
                        controller: _employeesCtrl,
                        isNumber: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSectionTitle("Tax Information"),
                _buildTextField(label: "GST Number", controller: _gstCtrl),
                _buildTextField(label: "PAN Number", controller: _panCtrl),

                const SizedBox(height: 16),
                _buildSectionTitle("Address"),
                _buildTextField(
                  label: "Address Line 1",
                  controller: _address1Ctrl,
                ),
                _buildTextField(
                  label: "Address Line 2",
                  controller: _address2Ctrl,
                ),
                _buildTextField(label: "Landmark", controller: _landmarkCtrl),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: "City",
                        controller: _cityCtrl,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: "State",
                        controller: _stateCtrl,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: "Pincode",
                        controller: _pincodeCtrl,
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        label: "Country",
                        controller: _countryCtrl,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEdit ? "Save Changes" : "Register Company"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool isNumber = false,
  }) {
    final isPan = label.toLowerCase().contains('pan');
    final isGst = label.toLowerCase().contains('gst');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: isNumber ? 10 : null,
        inputFormatters: isPan
            ? const [TaxIdInputFormatter.pan()]
            : isGst
            ? const [TaxIdInputFormatter.gst()]
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          final taxError = isPan
              ? TaxIdValidator.pan(value, required: true)
              : isGst
              ? TaxIdValidator.gst(value, required: true)
              : null;
          if (taxError != null) return taxError;
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }
}
