import 'package:daalsetu/utils/company_location.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/tax_id_formatters.dart';
import '../../../../utils/india_location_data.dart';
import '../../../../widgets/searchable_selection_sheet.dart';
import '../controller/transporter_company_controller.dart';
import '../model/company_model.dart';
import '../../../../routes/app_routes.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import '../../../../utils/app_snackbar.dart';

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

  final Set<String> _customCities = {};

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

    _pincodeCtrl.addListener(_onPincodeChanged);
    _loadStates();
  }

  /// States / cities of the selected country (India: built-in list; elsewhere from the server).
  List<String> _states = const [];
  List<String> _cities = const [];

  String get _country =>
      _countryCtrl.text.trim().isEmpty ? CompanyLocation.india : _countryCtrl.text.trim();

  bool get _isIndia => CompanyLocation.isIndia(_country);

  Future<void> _loadStates() async {
    final states = await CompanyLocation.states(_country);
    if (!mounted) return;
    setState(() => _states = states);
    await _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await CompanyLocation.cities(_country, _stateCtrl.text);
    if (!mounted) return;
    setState(() => _cities = cities);
  }

  void _onPincodeChanged() {
    final pin = _pincodeCtrl.text.trim();
    if (_isIndia && pin.length == 6) {
      final detected = IndiaLocationData.getStateFromPincode(pin);
      if (detected != null &&
          detected.toLowerCase() != _stateCtrl.text.trim().toLowerCase()) {
        setState(() {
          _stateCtrl.text = detected;
        });
      }
    }
  }

  @override
  void dispose() {
    _pincodeCtrl.removeListener(_onPincodeChanged);
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
    final gstPanError = _isIndia
        ? TaxIdValidator.gstMatchesPan(_panCtrl.text, _gstCtrl.text)
        : null;
    if (gstPanError != null) {
      AppSnackbar.snackbar('Validation error', gstPanError);
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      "legal_name": _legalNameCtrl.text.trim(),
      "company_type": _typeCtrl.text.trim(),
      "year_of_establishment": int.tryParse(_yearCtrl.text.trim()),
      "number_of_employees": int.tryParse(_employeesCtrl.text.trim()),
      // A company outside India has no PAN / GST (the server drops them too).
      "gst_number": _isIndia ? _gstCtrl.text.trim().toUpperCase() : "",
      "pan_number": _isIndia ? _panCtrl.text.trim().toUpperCase() : "",
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
      Get.until(
        (route) =>
            route.settings.name == AppRoutes.transporterCompany ||
            route.settings.name == AppRoutes.mainNav ||
            route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.company != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: isEdit ? "Edit Company" : "Register Company",
        subtitle: isEdit
            ? (widget.company?.legalName ?? "Update company details")
            : "Enter company registration & tax details",
        leading: AppBarLeading(
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
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
                  label: "Company Type",
                  controller: _typeCtrl,
                  hintText: "e.g. Private Limited",
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

                // PAN / GST are Indian tax ids; GST is optional.
                if (_isIndia) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle("Tax Information"),
                  _buildTextField(
                    label: "GST Number (optional)",
                    controller: _gstCtrl,
                    validateGst: true,
                  ),
                  _buildTextField(
                    label: "PAN Number",
                    controller: _panCtrl,
                    isRequired: true,
                    validatePan: true,
                  ),
                ],

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
                _buildCountryField(),
                Row(
                  children: [
                    Expanded(child: _buildCityDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStateDropdown()),
                  ],
                ),
                _buildPostalCodeField(),

                const SizedBox(height: 32),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE65100).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isEdit ? "Save Changes" : "Register Company",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
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
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool isNumber = false,
    bool validatePan = false,
    bool validateGst = false,
    String? hintText,
  }) {
    final lower = label.toLowerCase();
    final isYear = lower.contains('year');
    final isEmployees = lower.contains('employee');
    final isPincode = lower.contains('pincode');
    final isCompanyType = lower.contains('company type');

    final effectiveHint =
        hintText ??
        (validateGst
            ? "e.g. 22AAAAA0000A1Z5"
            : validatePan
            ? "e.g. ABCDE1234F"
            : isCompanyType
            ? "e.g. Private Limited"
            : isYear
            ? "e.g. 2019"
            : isEmployees
            ? "e.g. 25"
            : isPincode
            ? "e.g. 400001"
            : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: validateGst
            ? 15
            : isNumber
            ? 10
            : null,
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        inputFormatters: validatePan
            ? const [TaxIdInputFormatter.pan()]
            : validateGst
            ? const [TaxIdInputFormatter.gst()]
            : null,
        decoration: InputDecoration(
          label: isRequired
              ? Text.rich(
                  TextSpan(
                    text: label,
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(label),
          labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
          hintText: effectiveHint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: "",
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252525)
              : const Color(0xFFFFF8E1).withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF333333)
                  : const Color(0xFFFFE0B2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF333333)
                  : const Color(0xFFFFE0B2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
          ),
        ),
        validator: (value) {
          final taxError = validatePan
              ? TaxIdValidator.pan(value, required: isRequired)
              : validateGst
              ? TaxIdValidator.gst(value, required: isRequired)
              : null;
          if (taxError != null) return taxError;
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return "$label is required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCityDropdown() {
    final availableCities = _getAvailableCities();
    final currentCity = _cityCtrl.text.trim();
    final selectedCity =
        availableCities.contains(currentCity) && currentCity.isNotEmpty
        ? currentCity
        : null;

    return _selectionFormField(
      key: ValueKey("city_${_stateCtrl.text}_$selectedCity"),
      label: 'City',
      hint: 'Select City',
      value: selectedCity,
      icon: Icons.location_city_outlined,
      validator: (_) => _cityCtrl.text.trim().isEmpty
          ? 'City is required'
          : null,
      onTap: (field) async {
        // Search the list or type a city that is not in it (same as the web).
        final selected = await showSearchableSelectionSheet<String>(
          context: context,
          title: 'Select City',
          searchHint: 'Search or type the city...',
          options: availableCities,
          selectedValue: selectedCity,
          labelBuilder: (value) => value,
          customOption: (typed) => typed,
        );
        if (!mounted || selected == null) return;
        _customCities.add(selected);
        setState(() {
          _cityCtrl.text = selected;
          if (!_isIndia) return;
          final inferredState = IndiaLocationData.getStateForCity(selected);
          if (inferredState != null &&
              _stateCtrl.text.trim().toLowerCase() !=
                  inferredState.toLowerCase()) {
            _stateCtrl.text = inferredState;
          }
        });
        field.didChange(selected);
      },
    );
  }

  Widget _buildCountryField() {
    return _selectionFormField(
      key: ValueKey('country_$_country'),
      label: 'Country',
      hint: 'Select Country',
      value: _country,
      icon: Icons.public,
      validator: (_) => _country.isEmpty ? 'Country is required' : null,
      onTap: (field) async {
        final countries = await CompanyLocation.countries();
        if (!mounted) return;
        final selected = await showSearchableSelectionSheet<String>(
          context: context,
          title: 'Select Country',
          searchHint: 'Search country...',
          options: countries,
          selectedValue: _country,
          labelBuilder: (value) => value,
        );
        if (!mounted || selected == null || selected == _country) return;
        setState(() {
          _countryCtrl.text = selected;
          // A new country: its own states, cities and postal code; PAN / GST only for India.
          _stateCtrl.clear();
          _cityCtrl.clear();
          _customCities.clear();
          _states = const [];
          _cities = const [];
        });
        field.didChange(selected);
        await _loadStates();
      },
    );
  }

  Widget _buildPostalCodeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _pincodeCtrl,
        keyboardType: _isIndia ? TextInputType.number : TextInputType.text,
        maxLength: 12,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          labelText: CompanyLocation.postalCodeLabel(_country),
          labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
          hintText: _isIndia ? 'e.g. 400001' : 'e.g. 44600',
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: '',
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252525)
              : const Color(0xFFFFF8E1).withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => CompanyLocation.postalCodeError(_country, value ?? ''),
      ),
    );
  }

  Widget _buildStateDropdown() {
    final states = List<String>.from(_states);
    final currentState = _stateCtrl.text.trim();
    final matched = states.firstWhere(
      (s) => s.toLowerCase() == currentState.toLowerCase(),
      orElse: () => '',
    );
    // A typed state (manual entry) is shown as it is.
    final matchedState = matched.isNotEmpty ? matched : (currentState.isEmpty ? null : currentState);

    return _selectionFormField(
      key: ValueKey("state_${_country}_$matchedState"),
      label: _isIndia ? 'State' : 'State / Province',
      hint: 'Select State',
      value: matchedState,
      icon: Icons.map_outlined,
      validator: (_) => _stateCtrl.text.trim().isEmpty
          ? 'State is required'
          : null,
      onTap: (field) async {
        // Search the list or type a state that is not in it (same as the web).
        final state = await showSearchableSelectionSheet<String>(
          context: context,
          title: 'Select State',
          searchHint: 'Search or type the state...',
          options: states,
          selectedValue: matched.isNotEmpty ? matched : null,
          labelBuilder: (value) => value,
          customOption: (typed) => typed,
        );
        if (!mounted || state == null) return;
        setState(() {
          _stateCtrl.text = state;
          if (_isIndia) {
            final stateCities = IndiaLocationData.stateCities[state] ?? [];
            if (!stateCities.any(
              (city) => city.toLowerCase() == _cityCtrl.text.trim().toLowerCase(),
            )) {
              _cityCtrl.text = stateCities.isNotEmpty ? stateCities.first : '';
            }
          } else {
            _cityCtrl.clear();
          }
        });
        field.didChange(state);
        await _loadCities();
      },
    );
  }

  Widget _selectionFormField({
    required Key key,
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required Future<void> Function(FormFieldState<String> field) onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FormField<String>(
        key: key,
        initialValue: value,
        validator: validator,
        builder: (field) => Semantics(
          button: true,
          label: '$label selection',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(field),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                errorText: field.errorText,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: Icon(icon, color: const Color(0xFFE65100)),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF252525)
                    : const Color(0xFFFFF8E1).withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF333333)
                        : const Color(0xFFFFE0B2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF333333)
                        : const Color(0xFFFFE0B2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
                ),
              ),
              isEmpty: value == null || value.isEmpty,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? hint,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: value == null
                            ? theme.hintColor
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getAvailableCities() {
    if (!_isIndia) {
      final list = List<String>.from(_cities);
      final cur = _cityCtrl.text.trim();
      if (cur.isNotEmpty && !list.contains(cur)) list.insert(0, cur);
      return list;
    }
    final state = _stateCtrl.text.trim();
    final matched = IndiaLocationData.stateCities.keys.firstWhere(
      (k) => k.toLowerCase() == state.toLowerCase(),
      orElse: () => '',
    );
    final matchedKey = matched.isNotEmpty ? matched : null;

    List<String> list;
    if (matchedKey != null) {
      list = List<String>.from(IndiaLocationData.stateCities[matchedKey]!);
    } else {
      final all = <String>{};
      for (final cities in IndiaLocationData.stateCities.values) {
        all.addAll(cities);
      }
      list = all.toList()..sort();
    }

    for (final custom in _customCities) {
      if (!list.contains(custom)) {
        list.insert(0, custom);
      }
    }
    final cur = _cityCtrl.text.trim();
    if (cur.isNotEmpty && !list.contains(cur)) {
      list.insert(0, cur);
    }

    return list;
  }

}
