import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/transporter_vehicle_controller.dart';
import '../model/vehicle_model.dart';

class TransporterVehicleForm extends StatefulWidget {
  final VehicleModel? vehicle; // Null for create, provided for edit

  const TransporterVehicleForm({super.key, this.vehicle});

  @override
  State<TransporterVehicleForm> createState() => _TransporterVehicleFormState();
}

class _TransporterVehicleFormState extends State<TransporterVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final TransporterVehicleController controller = Get.find<TransporterVehicleController>();
  
  bool _isSubmitting = false;

  late TextEditingController _numberCtrl;
  late TextEditingController _modelNameCtrl;
  late TextEditingController _manufacturingYearCtrl;
  late TextEditingController _loadCapacityCtrl;
  late TextEditingController _axlesCtrl;
  late TextEditingController _rcNumberCtrl;
  late TextEditingController _insuranceNumberCtrl;
  late TextEditingController _insuranceExpiryCtrl;
  late TextEditingController _permitExpiryCtrl;

  String _vehicleType = 'Heavy Goods Vehicle';
  String _vehicleBrand = 'tata';
  String _fuelType = 'diesel';
  String _bodyType = 'open_body';
  String _permitType = 'national_permit';
  String _status = 'available';

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _numberCtrl = TextEditingController(text: v?.vehicleNumber ?? '');
    _modelNameCtrl = TextEditingController(text: v?.modelName ?? '');
    _manufacturingYearCtrl = TextEditingController(text: v?.manufacturingYear?.toString() ?? '');
    _loadCapacityCtrl = TextEditingController(text: v?.loadCapacityTons ?? '');
    _axlesCtrl = TextEditingController(text: v?.numberOfAxles?.toString() ?? '');
    _rcNumberCtrl = TextEditingController(text: v?.rcNumber ?? '');
    _insuranceNumberCtrl = TextEditingController(text: v?.insuranceNumber ?? '');
    _insuranceExpiryCtrl = TextEditingController(text: v?.insuranceExpiryDate ?? '');
    _permitExpiryCtrl = TextEditingController(text: v?.permitExpiryDate ?? '');

    if (v != null) {
      if (v.vehicleType.isNotEmpty) _vehicleType = v.vehicleType;
      if (v.vehicleBrand.isNotEmpty) _vehicleBrand = v.vehicleBrand;
      if (v.fuelType.isNotEmpty) _fuelType = v.fuelType;
      if (v.bodyType.isNotEmpty) _bodyType = v.bodyType;
      if (v.permitType?.isNotEmpty == true) _permitType = v.permitType!;
      if (v.vehicleStatus.isNotEmpty) _status = v.vehicleStatus;
    }
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _modelNameCtrl.dispose();
    _manufacturingYearCtrl.dispose();
    _loadCapacityCtrl.dispose();
    _axlesCtrl.dispose();
    _rcNumberCtrl.dispose();
    _insuranceNumberCtrl.dispose();
    _insuranceExpiryCtrl.dispose();
    _permitExpiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      "vehicle_number": _numberCtrl.text.trim(),
      "vehicle_type": _vehicleType,
      "vehicle_brand": _vehicleBrand,
      "model_name": _modelNameCtrl.text.trim(),
      "manufacturing_year": int.tryParse(_manufacturingYearCtrl.text.trim()),
      "fuel_type": _fuelType,
      "load_capacity_tons": _loadCapacityCtrl.text.trim(),
      "body_type": _bodyType,
      "number_of_axles": int.tryParse(_axlesCtrl.text.trim()),
      "rc_number": _rcNumberCtrl.text.trim(),
      "insurance_number": _insuranceNumberCtrl.text.trim(),
      "insurance_expiry_date": _insuranceExpiryCtrl.text.trim().isNotEmpty ? _insuranceExpiryCtrl.text.trim() : null,
      "permit_type": _permitType,
      "permit_expiry_date": _permitExpiryCtrl.text.trim().isNotEmpty ? _permitExpiryCtrl.text.trim() : null,
      "vehicle_status": _status,
    };

    bool success;
    if (widget.vehicle == null) {
      success = await controller.createVehicle(data);
    } else {
      success = await controller.updateVehicle(widget.vehicle!.id, data);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.vehicle != null;

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
                _buildSectionTitle("Basic Information"),
                _buildTextField(label: "Vehicle Number (e.g. MH31AB1234)", controller: _numberCtrl, isRequired: true),
                
                _buildDropdown(
                  label: "Vehicle Type",
                  value: _vehicleType,
                  items: const [
                    DropdownMenuItem(value: 'Heavy Goods Vehicle', child: Text("Heavy Goods Vehicle")),
                    DropdownMenuItem(value: 'Truck', child: Text("Truck")),
                    DropdownMenuItem(value: 'Light Commercial Vehicle', child: Text("Light Commercial Vehicle")),
                  ],
                  onChanged: (val) => setState(() => _vehicleType = val!),
                ),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Brand",
                        value: _vehicleBrand,
                        items: const [
                          DropdownMenuItem(value: 'tata', child: Text("Tata")),
                          DropdownMenuItem(value: 'ashok_leyland', child: Text("Ashok Leyland")),
                          DropdownMenuItem(value: 'eicher', child: Text("Eicher")),
                          DropdownMenuItem(value: 'mahindra', child: Text("Mahindra")),
                        ],
                        onChanged: (val) => setState(() => _vehicleBrand = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: "Fuel Type",
                        value: _fuelType,
                        items: const [
                          DropdownMenuItem(value: 'diesel', child: Text("Diesel")),
                          DropdownMenuItem(value: 'petrol', child: Text("Petrol")),
                          DropdownMenuItem(value: 'cng', child: Text("CNG")),
                        ],
                        onChanged: (val) => setState(() => _fuelType = val!),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(child: _buildTextField(label: "Model Name", controller: _modelNameCtrl)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(label: "Mfg Year", controller: _manufacturingYearCtrl, isNumber: true)),
                  ],
                ),
                
                const SizedBox(height: 16),
                _buildSectionTitle("Specifications"),
                Row(
                  children: [
                    Expanded(child: _buildTextField(label: "Load Cap. (Tons)", controller: _loadCapacityCtrl, isRequired: true, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(label: "Number of Axles", controller: _axlesCtrl, isNumber: true)),
                  ],
                ),
                
                _buildDropdown(
                  label: "Body Type",
                  value: _bodyType,
                  items: const [
                    DropdownMenuItem(value: 'open_body', child: Text("Open Body")),
                    DropdownMenuItem(value: 'closed_body', child: Text("Closed Body")),
                    DropdownMenuItem(value: 'container', child: Text("Container")),
                  ],
                  onChanged: (val) => setState(() => _bodyType = val!),
                ),

                const SizedBox(height: 16),
                _buildSectionTitle("Documentation"),
                _buildTextField(label: "RC Number", controller: _rcNumberCtrl),
                _buildTextField(label: "Insurance Number", controller: _insuranceNumberCtrl),
                _buildTextField(label: "Insurance Expiry (YYYY-MM-DD)", controller: _insuranceExpiryCtrl),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Permit Type",
                        value: _permitType,
                        items: const [
                          DropdownMenuItem(value: 'national_permit', child: Text("National Permit")),
                          DropdownMenuItem(value: 'state_permit', child: Text("State Permit")),
                        ],
                        onChanged: (val) => setState(() => _permitType = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(label: "Permit Expiry", controller: _permitExpiryCtrl)),
                  ],
                ),

                const SizedBox(height: 16),
                _buildSectionTitle("Status"),
                _buildDropdown(
                  label: "Vehicle Status",
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text("Available")),
                    DropdownMenuItem(value: 'in_transit', child: Text("In Transit")),
                    DropdownMenuItem(value: 'maintenance', child: Text("Maintenance")),
                  ],
                  onChanged: (val) => setState(() => _status = val!),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(isEdit ? "Save Changes" : "Register Vehicle"),
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
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
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
