import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/transporter_driver_controller.dart';
import '../model/driver_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../nav_bar/controller/nav_controller.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:daalsetu/utils/app_date.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.driver != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: isEdit ? "Edit Driver" : "Register Driver",
        subtitle: isEdit
            ? (widget.driver?.driverName ?? "Update driver details")
            : "Enter driver license & contact information",
        leading: AppBarLeading(
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
                      decoration: _decoration("License Expiry").copyWith(
                        suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFFE65100)),
                      ),
                      child: Text(
                        AppDate.date(_licenseExpiry, empty: 'Select date'),
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OutlinedButton.icon(
                    onPressed: _pickLicense,
                    icon: const Icon(Icons.upload_file, color: Color(0xFFE65100)),
                    label: Text(
                      _licenseFilePath != null
                          ? "License selected: ${_licenseFilePath!.split(RegExp(r'[\\/]')).last}"
                          : (widget.driver?.licenseUploadUrl != null ? "License uploaded (tap to replace)" : "Upload driving license"),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      side: const BorderSide(color: Color(0xFFFFB300), width: 1.2),
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

                const SizedBox(height: 24),
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
                            isEdit ? "Save Changes" : "Register Driver",
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

  InputDecoration _decoration(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
      counterText: "",
      filled: true,
      fillColor: isDark ? const Color(0xFF252525) : const Color(0xFFFFF8E1).withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFFFE0B2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
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
