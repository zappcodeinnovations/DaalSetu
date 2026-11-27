import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:daalsetu/utils/company_location.dart';
import 'package:daalsetu/utils/india_location_data.dart';
import 'package:daalsetu/utils/tax_id_formatters.dart';
import 'package:daalsetu/widgets/searchable_selection_sheet.dart';
import '../controller/seller_company_controller.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class AddCompanyView extends StatefulWidget {
  const AddCompanyView({super.key});

  @override
  State<AddCompanyView> createState() => _AddCompanyViewState();
}

class _AddCompanyViewState extends State<AddCompanyView> {
  static const Color primaryColor = AppTheme.secondaryOrange;
  final Set<String> _customCities = {};
  late final SellerCompanyController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SellerCompanyController>()
        ? Get.find<SellerCompanyController>()
        : Get.put(SellerCompanyController());
    controller.pincodeController.addListener(_onPincodeChanged);
    _loadStates();
  }

  /// States of the selected country (India: built-in list; elsewhere from the server, may be empty).
  List<String> _states = const [];
  List<String> _cities = const [];

  String get _country => controller.countryController.text.trim().isEmpty
      ? CompanyLocation.india
      : controller.countryController.text.trim();

  bool get _isIndia => CompanyLocation.isIndia(_country);

  Future<void> _loadStates() async {
    final states = await CompanyLocation.states(_country);
    if (!mounted) return;
    setState(() => _states = states);
    await _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await CompanyLocation.cities(_country, controller.stateController.text);
    if (!mounted) return;
    setState(() => _cities = cities);
  }

  Future<void> _pickCountry() async {
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
    controller.clearError('country');
    setState(() {
      controller.countryController.text = selected;
      // A new country: its own states, cities and postal code; PAN / GST only for India.
      controller.stateController.clear();
      controller.cityController.clear();
      _customCities.clear();
      _states = const [];
      _cities = const [];
    });
    await _loadStates();
  }

  @override
  void dispose() {
    controller.pincodeController.removeListener(_onPincodeChanged);
    super.dispose();
  }

  void _onPincodeChanged() {
    final pin = controller.pincodeController.text.trim();
    if (_isIndia && pin.length == 6) {
      final detected = IndiaLocationData.getStateFromPincode(pin);
      if (detected != null &&
          detected.toLowerCase() !=
              controller.stateController.text.trim().toLowerCase()) {
        setState(() {
          controller.stateController.text = detected;
        });
      }
    }
  }

  List<String> _getAvailableCities() {
    if (!_isIndia) {
      final list = List<String>.from(_cities);
      final cur = controller.cityController.text.trim();
      if (cur.isNotEmpty && !list.contains(cur)) list.insert(0, cur);
      return list;
    }
    final state = controller.stateController.text.trim();
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
    final cur = controller.cityController.text.trim();
    if (cur.isNotEmpty && !list.contains(cur)) {
      list.insert(0, cur);
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: controller.isEditing.value ? "Edit Company" : "Register Company",
        subtitle: "Enterprise identity, GST & branch details",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom > 0 ? 120 : 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Company Details", theme),
              _buildTextField(
                controller.legalNameController,
                "Legal Name",
                IconlyLight.home,
                required: true,
              ),
              _buildTextField(
                controller.companyTypeController,
                "Company Type",
                IconlyLight.category,
                placeholder: "e.g. Private Limited",
              ),
              _buildTextField(
                controller.yearController,
                "Year of Establishment",
                IconlyLight.calendar,
                keyboardType: TextInputType.number,
                errorKey: 'year_of_establishment',
                required: true,
              ),
              _buildTextField(
                controller.employeesController,
                "Number of Employees",
                IconlyLight.user_1,
                keyboardType: TextInputType.number,
                errorKey: 'number_of_employees',
              ),
              // PAN / GST are Indian tax ids; GST is optional.
              if (_isIndia) ...[
                _buildSectionHeader("STATUTORY DETAILS", theme),
                _buildTextField(
                  controller.panController,
                  "PAN Number",
                  IconlyLight.document,
                  textCapitalization: TextCapitalization.characters,
                  errorKey: 'pan_number',
                  required: true,
                ),
                _buildTextField(
                  controller.gstController,
                  "GST Number (optional)",
                  IconlyLight.document,
                  textCapitalization: TextCapitalization.characters,
                  errorKey: 'gst_number',
                ),
              ],
              _buildSectionHeader("Registered Address", theme),
              _buildTextField(
                controller.address1Controller,
                "Address Line 1",
                IconlyLight.location,
                errorKey: 'address_line_1',
                required: true,
              ),
              _buildTextField(
                controller.address2Controller,
                "Address Line 2",
                IconlyLight.location,
              ),
              _buildTextField(
                controller.landmarkController,
                "Landmark",
                IconlyLight.location,
                errorKey: 'landmark',
              ),
              _buildCountryField(theme),
              _buildStateDropdown(theme),
              _buildCityDropdown(theme),
              _buildTextField(
                controller.pincodeController,
                CompanyLocation.postalCodeLabel(_country),
                null,
                keyboardType: _isIndia ? TextInputType.number : TextInputType.text,
                errorKey: 'pincode',
                required: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: controller.saveCompany,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Obx(
                    () => Text(
                      controller.isEditing.value ? "UPDATE" : "SUBMIT",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    final availableCities = _getAvailableCities();
    final currentCity = controller.cityController.text.trim();
    final selectedCity =
        availableCities.contains(currentCity) && currentCity.isNotEmpty
        ? currentCity
        : null;

    return Obx(() {
      final errorText = controller.errors['city'];
      return _selectionField(
        theme: theme,
        label: 'City',
        hint: 'Select City',
        value: selectedCity,
        icon: Icons.location_city_outlined,
        errorText: errorText,
        onTap: () async {
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
          controller.clearError('city');
          _customCities.add(selected);
          setState(() {
            controller.cityController.text = selected;
            if (!_isIndia) return;
            final inferredState = IndiaLocationData.getStateForCity(selected);
            if (inferredState != null &&
                controller.stateController.text.trim().toLowerCase() !=
                    inferredState.toLowerCase()) {
              controller.stateController.text = inferredState;
              controller.clearError('state');
            }
          });
        },
      );
    });
  }

  Widget _buildCountryField(ThemeData theme) {
    return Obx(() {
      final errorText = controller.errors['country'];
      return _selectionField(
        theme: theme,
        label: 'Country',
        hint: 'Select Country',
        value: _country,
        icon: Icons.public,
        errorText: errorText,
        onTap: _pickCountry,
      );
    });
  }

  Widget _buildStateDropdown(ThemeData theme) {
    final states = List<String>.from(_states);
    final currentState = controller.stateController.text.trim();
    final matched = states.firstWhere(
      (s) => s.toLowerCase() == currentState.toLowerCase(),
      orElse: () => '',
    );
    // A typed state (manual entry) is shown as it is.
    final matchedState = matched.isNotEmpty ? matched : (currentState.isEmpty ? null : currentState);

    return Obx(() {
      final errorText = controller.errors['state'];
      return _selectionField(
        theme: theme,
        label: _isIndia ? 'State' : 'State / Province',
        hint: _isIndia ? 'Select State' : 'Select or type the state',
        value: matchedState,
        icon: Icons.map_outlined,
        errorText: errorText,
        onTap: () async {
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
          controller.clearError('state');
          setState(() {
            controller.stateController.text = state;
            if (_isIndia) {
              final stateCities = IndiaLocationData.stateCities[state] ?? [];
              if (!stateCities.any(
                (city) => city.toLowerCase() == controller.cityController.text.trim().toLowerCase(),
              )) {
                controller.cityController.text = stateCities.isNotEmpty ? stateCities.first : '';
              }
            } else {
              controller.cityController.clear();
            }
          });
          await _loadCities();
        },
      );
    });
  }

  Widget _selectionField({
    required ThemeData theme,
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Semantics(
        button: true,
        label: '$label selection',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: InputDecorator(
            decoration: _dropdownDecoration(
              theme: theme,
              label: label,
              required: true,
              icon: icon,
              errorText: errorText,
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
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required ThemeData theme,
    required String label,
    required IconData icon,
    String? errorText,
    bool required = false,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      label: required
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
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      errorText: errorText,
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        fontSize: 12,
        color: Colors.red,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: theme.dividerColor.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static bool _isTaxField(String text, String key) {
    final clean = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .trim();
    final words = clean.split(RegExp(r'\s+'));
    return words.contains(key);
  }

  Widget _buildTextField(
    TextEditingController textController,
    String hint,
    IconData? icon, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? placeholder,
    String? errorKey,
    bool required = false,
  }) {
    final isPan = _isTaxField(hint, 'pan');
    final isGst = _isTaxField(hint, 'gst');
    final clean = hint.toLowerCase();
    final isYear = clean.contains('year');
    final isPincode = clean.contains('pincode');
    final isCompanyType = clean.contains('company type');
    final isLegalName = clean.contains('legal name');

    final effectiveKey =
        errorKey ??
        (isLegalName
            ? 'legal_name'
            : isPan
            ? 'pan'
            : isGst
            ? 'gst'
            : isPincode
            ? 'pincode'
            : null);

    final effectiveHint =
        placeholder ??
        (isGst
            ? "e.g. 22AAAAA0000A1Z5"
            : isPan
            ? "e.g. ABCDE1234F"
            : isCompanyType
            ? "e.g. Private Limited"
            : isYear
            ? "e.g. 2019"
            : isPincode
            ? "e.g. 400001"
            : hint);

    Widget buildField(String? errorText) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: TextField(
          controller: textController,
          onChanged: (val) {
            if (effectiveKey != null &&
                controller.errors.containsKey(effectiveKey)) {
              controller.clearError(effectiveKey);
            }
          },
          keyboardType: keyboardType,
          maxLength: isGst
              ? 15
              : keyboardType == TextInputType.number
              ? 10
              : null,
          buildCounter:
              (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          inputFormatters: isPan
              ? const [TaxIdInputFormatter.pan()]
              : isGst
              ? const [TaxIdInputFormatter.gst()]
              : null,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            label: required
                ? Text.rich(
                    TextSpan(
                      text: hint,
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
                : Text(hint),
            hintText: effectiveHint,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            counterText: "",
            errorText: errorText,
            errorMaxLines: 3,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
          ),
        ),
      );
    }

    if (effectiveKey == null) {
      return buildField(null);
    }

    return Obx(() {
      final errorText = controller.errors[effectiveKey];
      return buildField(errorText);
    });
  }
}
