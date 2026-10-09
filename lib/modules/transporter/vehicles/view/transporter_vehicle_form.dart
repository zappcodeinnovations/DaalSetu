import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_vehicle_controller.dart';
import '../model/vehicle_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../nav_bar/controller/nav_controller.dart';

/// Same fields as the web "Register Vehicle" form. Dropdown values are the backend choices,
/// so editing a vehicle never hits a value the dropdown does not know.
class TransporterVehicleForm extends StatefulWidget {
  final VehicleModel? vehicle; // Null for create, provided for edit

  const TransporterVehicleForm({super.key, this.vehicle});

  @override
  State<TransporterVehicleForm> createState() => _TransporterVehicleFormState();
}

class _TransporterVehicleFormState extends State<TransporterVehicleForm> {
  static const _brands = {
    'tata': 'Tata', 'mahindra': 'Mahindra', 'ashok_leyland': 'Ashok Leyland', 'eicher': 'Eicher',
    'bharatbenz': 'BharatBenz', 'isuzu': 'Isuzu', 'other': 'Other',
  };
  static const _fuels = {'diesel': 'Diesel', 'petrol': 'Petrol', 'cng': 'CNG', 'electric': 'Electric'};
  static const _bodies = {
    'open_body': 'Open Body', 'closed_body': 'Closed Body', 'container': 'Container', 'flatbed': 'Flatbed',
    'refrigerated': 'Refrigerated', 'tanker': 'Tanker', 'other': 'Other',
  };
  static const _permits = {'national_permit': 'National Permit', 'state_permit': 'State Permit', 'other': 'Other'};

  final _formKey = GlobalKey<FormState>();
  final TransporterVehicleController controller = Get.find<TransporterVehicleController>();
  bool _isSubmitting = false;

  late final TextEditingController _numberCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _modelNameCtrl;
  late final TextEditingController _loadCapacityCtrl;
  late final TextEditingController _lengthCtrl;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _rcNumberCtrl;
  late final TextEditingController _insuranceNumberCtrl;
  late final TextEditingController _brandOtherCtrl;
  late final TextEditingController _bodyOtherCtrl;
  late final TextEditingController _permitOtherCtrl;

  String? _brand;
  String? _fuel;
  String? _body;
  String? _permit;
  int? _year;
  int? _axles;
  String _status = 'available';
  String? _insuranceExpiry;
  String? _permitExpiry;
  String? _rcFilePath;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    TextEditingController ctrl(String? text) => TextEditingController(text: text ?? '');
    _numberCtrl = ctrl(v?.vehicleNumber);
    _typeCtrl = ctrl(v?.vehicleType);
    _modelNameCtrl = ctrl(v?.modelName);
    _loadCapacityCtrl = ctrl(v?.loadCapacityTons);
    _lengthCtrl = ctrl(v?.lengthFt);
    _widthCtrl = ctrl(v?.widthFt);
    _heightCtrl = ctrl(v?.heightFt);
    _rcNumberCtrl = ctrl(v?.rcNumber);
    _insuranceNumberCtrl = ctrl(v?.insuranceNumber);
    _brandOtherCtrl = ctrl(v?.vehicleBrandOther);
    _bodyOtherCtrl = ctrl(v?.bodyTypeOther);
    _permitOtherCtrl = ctrl(v?.permitTypeOther);
    // Only keep values the dropdowns know; anything else starts empty instead of crashing.
    _brand = _brands.containsKey(v?.vehicleBrand) ? v!.vehicleBrand : null;
    _fuel = _fuels.containsKey(v?.fuelType) ? v!.fuelType : null;
    _body = _bodies.containsKey(v?.bodyType) ? v!.bodyType : null;
    _permit = _permits.containsKey(v?.permitType) ? v!.permitType : null;
    _year = v?.manufacturingYear;
    _axles = v?.numberOfAxles;
    if (TransporterVehicleController.statusLabels.containsKey(v?.vehicleStatus)) _status = v!.vehicleStatus;
    _insuranceExpiry = v?.insuranceExpiryDate;
    _permitExpiry = v?.permitExpiryDate;
  }

  @override
  void dispose() {
    for (final c in [
      _numberCtrl, _typeCtrl, _modelNameCtrl, _loadCapacityCtrl, _lengthCtrl, _widthCtrl, _heightCtrl,
      _rcNumberCtrl, _insuranceNumberCtrl, _brandOtherCtrl, _bodyOtherCtrl, _permitOtherCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(String? current, ValueChanged<String> onPicked) async {
    // Backend rejects past expiry dates.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = DateTime.tryParse(current ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: existing != null && !existing.isBefore(today) ? existing : today,
      firstDate: today,
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) {
      setState(() => onPicked("${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}"));
    }
  }

  Future<void> _pickRc() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _rcFilePath = file.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final data = <String, dynamic>{
      "vehicle_number": _numberCtrl.text.trim().toUpperCase().replaceAll(' ', ''),
      "vehicle_type": _typeCtrl.text.trim(),
      "vehicle_brand": _brand,
      "vehicle_brand_other": _brand == 'other' ? text(_brandOtherCtrl) : '',
      "model_name": _modelNameCtrl.text.trim(),
      "manufacturing_year": _year,
      "fuel_type": _fuel,
      "load_capacity_tons": _loadCapacityCtrl.text.trim(),
      "body_type": _body,
      "body_type_other": _body == 'other' ? text(_bodyOtherCtrl) : '',
      "length_ft": text(_lengthCtrl),
      "width_ft": text(_widthCtrl),
      "height_ft": text(_heightCtrl),
      "number_of_axles": _axles,
      "rc_number": _rcNumberCtrl.text.trim(),
      "insurance_number": _insuranceNumberCtrl.text.trim(),
      "insurance_expiry_date": _insuranceExpiry,
      // The web form submits an empty string for its optional Permit Type.
      // Sending null makes DRF reject the non-nullable model field.
      "permit_type": _permit ?? '',
      "permit_type_other": _permit == 'other' ? text(_permitOtherCtrl) : '',
      "permit_expiry_date": _permitExpiry,
      "vehicle_status": _status,
    };

    final success = await controller.saveVehicle(id: widget.vehicle?.id, data: data, rcFilePath: _rcFilePath);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().changeIndex(3);
      }
      Get.until((route) => route.settings.name == AppRoutes.transporterVehicles || route.settings.name == AppRoutes.mainNav || route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.vehicle != null;
    final years = [for (var y = DateTime.now().year; y >= 1990; y--) y];

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
          isEdit ? "Edit Vehicle" : "Register Vehicle",
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
                _sectionTitle("Basic Information"),
                _textField("Vehicle Number * (e.g. MH31AB1234)", _numberCtrl, required: true),
                _textField("Vehicle Type * (e.g. Truck, Trailer)", _typeCtrl, required: true),
                _dropdown<String>("Brand *", _brand, _brands, (v) => setState(() => _brand = v), required: true),
                if (_brand == 'other') _textField("Brand Name *", _brandOtherCtrl, required: true),
                _textField("Model Name", _modelNameCtrl),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown<int>("Mfg Year *", _year, {for (final y in years) y: '$y'},
                          (v) => setState(() => _year = v), required: true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _dropdown<String>("Fuel *", _fuel, _fuels, (v) => setState(() => _fuel = v), required: true)),
                  ],
                ),

                _sectionTitle("Specifications"),
                Row(
                  children: [
                    Expanded(child: _textField("Capacity (Tons) *", _loadCapacityCtrl, required: true, number: true)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown<int>("Axles *", _axles, {for (var a = 1; a <= 6; a++) a: '$a'},
                          (v) => setState(() => _axles = v), required: true),
                    ),
                  ],
                ),
                _dropdown<String>("Body Type *", _body, _bodies, (v) => setState(() => _body = v), required: true),
                if (_body == 'other') _textField("Body Type Name *", _bodyOtherCtrl, required: true),
                Row(
                  children: [
                    Expanded(child: _textField("Length (ft)", _lengthCtrl, number: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField("Width (ft)", _widthCtrl, number: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField("Height (ft)", _heightCtrl, number: true)),
                  ],
                ),

                _sectionTitle("Documents"),
                _textField("RC Number", _rcNumberCtrl),
                _fileTile(
                  _rcFilePath != null
                      ? "RC selected: ${_rcFilePath!.split(RegExp(r'[\\/]')).last}"
                      : (widget.vehicle?.rcUploadUrl != null ? "RC already uploaded (tap to replace)" : "Upload RC document"),
                  _pickRc,
                ),
                _textField("Insurance Number", _insuranceNumberCtrl),
                _dateTile("Insurance Expiry", _insuranceExpiry, (v) => _insuranceExpiry = v),
                _dropdown<String>("Permit Type", _permit, _permits, (v) => setState(() => _permit = v)),
                if (_permit == 'other') _textField("Permit Name", _permitOtherCtrl),
                _dateTile("Permit Expiry", _permitExpiry, (v) => _permitExpiry = v),

                _sectionTitle("Status"),
                _dropdown<String>("Vehicle Status", _status, TransporterVehicleController.statusLabels,
                    (v) => setState(() => _status = v ?? 'available')),

                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? "Save Changes" : "Register Vehicle"),
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

  Widget _textField(String label, TextEditingController controller, {bool required = false, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        maxLength: number ? 10 : null,
        decoration: _decoration(label),
        validator: (value) => required && (value == null || value.trim().isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _dropdown<T>(String label, T? value, Map<T, String> options, ValueChanged<T?> onChanged, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        initialValue: options.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: _decoration(label),
        items: options.entries.map((e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
        validator: (v) => required && v == null ? "Required" : null,
      ),
    );
  }

  Widget _dateTile(String label, String? value, ValueChanged<String> onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _pickDate(value, onPicked),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: _decoration(label).copyWith(suffixIcon: const Icon(Icons.calendar_month)),
          child: Text(value == null || value.isEmpty ? 'Select date' : value),
        ),
      ),
    );
  }

  Widget _fileTile(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.upload_file),
        label: Text(text, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
