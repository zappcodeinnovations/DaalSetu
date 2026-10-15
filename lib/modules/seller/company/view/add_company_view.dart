import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:daalsetu/utils/india_location_data.dart';
import 'package:daalsetu/utils/tax_id_formatters.dart';
import '../controller/seller_company_controller.dart';

class AddCompanyView extends StatefulWidget {
  const AddCompanyView({super.key});

  @override
  State<AddCompanyView> createState() => _AddCompanyViewState();
}

class _AddCompanyViewState extends State<AddCompanyView> {
  static const Color primaryColor = Color(0xFFFFB300);
  final Set<String> _customCities = {};
  late final SellerCompanyController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SellerCompanyController>();
    controller.pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    controller.pincodeController.removeListener(_onPincodeChanged);
    super.dispose();
  }

  void _onPincodeChanged() {
    final pin = controller.pincodeController.text.trim();
    if (pin.length == 6) {
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

  void _showCustomCityDialog() {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Enter City Name"),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: "e.g. Wardha",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newCity = textController.text.trim();
              if (newCity.isNotEmpty) {
                setState(() {
                  _customCities.add(newCity);
                  controller.cityController.text = newCity;
                });
                Get.back();
              }
            },
            child: const Text("Select"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(
          () => Text(
            controller.isEditing.value
                ? "Edit Company"
                : "Register New Company",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Company Details", theme),
            _buildTextField(
              controller.legalNameController,
              "Legal Name",
              IconlyLight.home,
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
            ),
            _buildSectionHeader("PAN & GST", theme),
            _buildTextField(
              controller.panController,
              "PAN Number",
              IconlyLight.document,
              textCapitalization: TextCapitalization.characters,
            ),
            _buildTextField(
              controller.gstController,
              "GST Number",
              IconlyLight.document,
              textCapitalization: TextCapitalization.characters,
            ),
            _buildSectionHeader("Registered Address", theme),
            _buildTextField(
              controller.address1Controller,
              "Address Line 1",
              IconlyLight.location,
            ),
            _buildTextField(
              controller.address2Controller,
              "Address Line 2",
              IconlyLight.location,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildCityDropdown(theme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStateDropdown(theme),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller.pincodeController,
                    "Pincode",
                    null,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller.countryController,
                    "Country",
                    null,
                  ),
                ),
              ],
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
    );
  }

  Widget _buildCityDropdown(ThemeData theme) {
    final availableCities = _getAvailableCities();
    final currentCity = controller.cityController.text.trim();
    final selectedCity =
        availableCities.contains(currentCity) && currentCity.isNotEmpty
            ? currentCity
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        key: ValueKey("city_${controller.stateController.text}_$selectedCity"),
        initialValue: selectedCity,
        isExpanded: true,
        menuMaxHeight: 320,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          labelText: "City",
          hintText: "Select City",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: "",
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
        ),
        items: [
          ...availableCities.map((city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(
                city,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }),
          const DropdownMenuItem<String>(
            value: "__custom__",
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Other (Custom City)",
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
        onChanged: (val) {
          if (val == "__custom__") {
            _showCustomCityDialog();
          } else if (val != null) {
            setState(() {
              controller.cityController.text = val;
              final inferredState = IndiaLocationData.getStateForCity(val);
              if (inferredState != null &&
                  controller.stateController.text.trim().toLowerCase() !=
                      inferredState.toLowerCase()) {
                controller.stateController.text = inferredState;
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildStateDropdown(ThemeData theme) {
    final states = IndiaLocationData.stateCities.keys.toList()..sort();
    final currentState = controller.stateController.text.trim();
    final matched = states.firstWhere(
      (s) => s.toLowerCase() == currentState.toLowerCase(),
      orElse: () => '',
    );
    final matchedState = matched.isNotEmpty ? matched : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        key: ValueKey("state_$matchedState"),
        initialValue: matchedState,
        isExpanded: true,
        menuMaxHeight: 320,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          labelText: "State",
          hintText: "Select State",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: "",
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
        ),
        items: states.map((state) {
          return DropdownMenuItem<String>(
            value: state,
            child: Text(
              state,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              controller.stateController.text = val;
              final stateCities = IndiaLocationData.stateCities[val] ?? [];
              if (!stateCities.any((c) =>
                  c.toLowerCase() ==
                  controller.cityController.text.trim().toLowerCase())) {
                controller.cityController.text =
                    stateCities.isNotEmpty ? stateCities.first : '';
              }
            });
          }
        },
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
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').trim();
    final words = clean.split(RegExp(r'\s+'));
    return words.contains(key);
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData? icon, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? placeholder,
  }) {
    final isPan = _isTaxField(hint, 'pan');
    final isGst = _isTaxField(hint, 'gst');
    final clean = hint.toLowerCase();
    final isYear = clean.contains('year');
    final isPincode = clean.contains('pincode');
    final isCompanyType = clean.contains('company type');

    final effectiveHint = placeholder ??
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: keyboardType == TextInputType.number ? 10 : null,
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
          labelText: hint,
          hintText: effectiveHint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: "",
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
        ),
      ),
    );
  }
}
