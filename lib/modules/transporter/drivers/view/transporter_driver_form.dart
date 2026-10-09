import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_driver_controller.dart';
import '../model/driver_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../nav_bar/controller/nav_controller.dart';

/// Same fields as the web "Register Driver" form, including the license upload.
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

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _licenseNumberCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _addressCtrl;

  String? _licenseExpiry;
  String? _licenseFilePath;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _nameCtrl = TextEditingController(text: d?.driverName ?? '');
    _phoneCtrl = TextEditingController(text: d?.phoneNumber ?? '');
    _emailCtrl = TextEditingController(text: d?.email ?? '');
    _licenseNumberCtrl = TextEditingController(text: d?.licenseNumber ?? '');
    _experienceCtrl = TextEditingController(text: d?.experience?.toString() ?? '');
    _addressCtrl = TextEditingController(text: d?.address ?? '');
    _licenseExpiry = (d?.licenseExpiry ?? '').isEmpty ? null : d!.licenseExpiry;
    if (d?.status == 'inactive') _status = 'inactive';
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl, _licenseNumberCtrl, _experienceCtrl, _addressCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = DateTime.tryParse(_licenseExpiry ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: existing != null && !existing.isBefore(today) ? existing : today,
      firstDate: today,
      lastDate: DateTime(now.year + 25),
    );
    if (picked != null) {
      setState(() => _licenseExpiry =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  Future<void> _pickLicense() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _licenseFilePath = file.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final data = <String, dynamic>{
      "driver_name": _nameCtrl.text.trim(),
      "phone_number": _phoneCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "license_number": _licenseNumberCtrl.text.trim().toUpperCase(),
      "license_expiry": _licenseExpiry,
      "experience": int.tryParse(_experienceCtrl.text.trim()) ?? 0,
      "address": _addressCtrl.text.trim(),
      "status": _status,
    };

    final success = await controller.saveDriver(id: widget.driver?.id, data: data, licenseFilePath: _licenseFilePath);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().changeIndex(2);
      }
      Get.until((route) => route.settings.name == AppRoutes.transporterDrivers || route.settings.name == AppRoutes.mainNav || route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.driver != null;

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
          isEdit ? "Edit Driver" : "Register Driver",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle("Personal Details"),
                _textField("Driver Name *", _nameCtrl, required: true),
                _textField("Phone Number *", _phoneCtrl,
                    required: true,
                    keyboard: TextInputType.phone,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) => (v ?? '').trim().length < 10 ? "Phone number must be 10-15 digits" : null),
                _textField("Email", _emailCtrl,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) => (v ?? '').trim().isNotEmpty && !GetUtils.isEmail(v!.trim()) ? "Enter a valid email" : null),

                _sectionTitle("License & Experience"),
                _textField("License Number *", _licenseNumberCtrl, required: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: _pickExpiry,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _decoration("License Expiry").copyWith(suffixIcon: const Icon(Icons.calendar_month)),
                      child: Text(_licenseExpiry ?? 'Select date'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _pickLicense,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      _licenseFilePath != null
                          ? "License selected: ${_licenseFilePath!.split(RegExp(r'[\\/]')).last}"
                          : (widget.driver?.licenseUploadUrl != null ? "License uploaded (tap to replace)" : "Upload driving license"),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                _textField("Experience (Years)", _experienceCtrl,
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),

                _sectionTitle("Other Details"),
                _textField("Address", _addressCtrl, maxLines: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: _decoration("Status"),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text("Active")),
                      DropdownMenuItem(value: 'inactive', child: Text("Inactive")),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? "Save Changes" : "Register Driver"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Text(title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      );

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        maxLines: maxLines,
        decoration: _decoration(label),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) return "This field is required";
          return validator?.call(value);
        },
      ),
    );
  }
}
