import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daalsetu/theme/glass_widgets.dart';
import 'package:daalsetu/modules/transporter/drivers/controller/transporter_driver_controller.dart';
import 'package:daalsetu/modules/transporter/drivers/model/driver_model.dart';
import 'package:daalsetu/utils/app_preferences.dart';

class TransporterDriverForm extends StatefulWidget {
  final DriverModel? driver; // Null for create, provided for edit

  const TransporterDriverForm({super.key, this.driver});

  @override
  State<TransporterDriverForm> createState() => _TransporterDriverFormState();
}

class _TransporterDriverFormState extends State<TransporterDriverForm> {
  final _formKey = GlobalKey<FormState>();
  final TransporterDriverController controller = Get.find<TransporterDriverController>();
  
  bool _isSubmitting = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _licenseNumberCtrl;
  late TextEditingController _licenseExpiryCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _addressCtrl;

  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _nameCtrl = TextEditingController(text: d?.driverName ?? '');
    _phoneCtrl = TextEditingController(text: d?.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: d?.email ?? '');
    _licenseNumberCtrl = TextEditingController(text: d?.licenseNumber ?? '');
    _licenseExpiryCtrl = TextEditingController(text: d?.licenseExpiry ?? '');
    _experienceCtrl = TextEditingController(text: d?.experience?.toString() ?? '');
    _addressCtrl = TextEditingController(text: d?.address ?? '');
    _status = d?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _licenseExpiryCtrl.dispose();
    _experienceCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final userIdStr = await AppPreferences.getUserId();
    final int? transporterId = int.tryParse(userIdStr ?? '');

    final data = {
      if (widget.driver == null && transporterId != null) "transporter_id": transporterId,
      "driver_name": _nameCtrl.text.trim(),
      "phone_number": _phoneCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "license_number": _licenseNumberCtrl.text.trim(),
      "license_expiry": _licenseExpiryCtrl.text.trim().isNotEmpty ? _licenseExpiryCtrl.text.trim() : null,
      "experience": int.tryParse(_experienceCtrl.text.trim()),
      "address": _addressCtrl.text.trim(),
      "status": _status,
    };

    bool success;
    if (widget.driver == null) {
      success = await controller.createDriver(data);
    } else {
      success = await controller.updateDriver(widget.driver!.id, data);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.driver != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? "Edit Driver" : "Register Driver",
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
                _buildSectionTitle("Personal Details"),
                _buildTextField(label: "Driver Name", controller: _nameCtrl, isRequired: true),
                _buildTextField(label: "Phone Number", controller: _phoneCtrl, isRequired: true, isNumber: true),
                _buildTextField(label: "Email", controller: _emailCtrl),
                
                const SizedBox(height: 16),
                _buildSectionTitle("License & Experience"),
                _buildTextField(label: "License Number", controller: _licenseNumberCtrl, isRequired: true),
                Row(
                  children: [
                    Expanded(child: _buildTextField(label: "Expiry (YYYY-MM-DD)", controller: _licenseExpiryCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(label: "Experience (Years)", controller: _experienceCtrl, isNumber: true)),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle("Other Details"),
                _buildTextField(label: "Address", controller: _addressCtrl),
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: "Status",
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text("Active")),
                      DropdownMenuItem(value: 'inactive', child: Text("Inactive")),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(isEdit ? "Save Changes" : "Register Driver"),
                  ),
                )
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }
}
