import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:daalsetu/utils/tax_id_formatters.dart';
import '../controller/seller_company_controller.dart';

class AddCompanyView extends StatelessWidget {
  const AddCompanyView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SellerCompanyController>();
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
                  child: _buildTextField(
                    controller.cityController,
                    "City",
                    null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller.stateController,
                    "State",
                    null,
                  ),
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
