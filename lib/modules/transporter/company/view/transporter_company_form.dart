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
  }

  void _onPincodeChanged() {
    final pin = _pincodeCtrl.text.trim();
    if (pin.length == 6) {
      final detected = _getStateFromPincode(pin);
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

                const SizedBox(height: 16),
                _buildSectionTitle("Tax Information"),
                _buildTextField(label: "GST Number", controller: _gstCtrl),
                _buildTextField(
                  label: "PAN Number",
                  controller: _panCtrl,
                  isRequired: true,
                ),

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
                      child: _buildCityDropdown(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStateDropdown(),
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
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
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

  static bool _isTaxField(String label, String key) {
    final clean = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ' ').trim();
    final words = clean.split(RegExp(r'\s+'));
    return words.contains(key);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isRequired = false,
    bool isNumber = false,
    String? hintText,
  }) {
    final isPan = _isTaxField(label, 'pan');
    final isGst = _isTaxField(label, 'gst');
    final lower = label.toLowerCase();
    final isYear = lower.contains('year');
    final isEmployees = lower.contains('employee');
    final isPincode = lower.contains('pincode');
    final isCompanyType = lower.contains('company type');

    final effectiveHint = hintText ??
        (isGst
            ? "e.g. 22AAAAA0000A1Z5"
            : isPan
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
        maxLength: isNumber ? 10 : null,
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        inputFormatters: isPan
            ? const [TaxIdInputFormatter.pan()]
            : isGst
            ? const [TaxIdInputFormatter.gst()]
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: effectiveHint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          counterText: "",
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          final taxError = isPan
              ? TaxIdValidator.pan(value, required: isRequired)
              : isGst
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
    final selectedCity = availableCities.contains(currentCity) && currentCity.isNotEmpty
        ? currentCity
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey("city_${_stateCtrl.text}_$selectedCity"),
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
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
                  "Other (Enter Custom City)",
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
              _cityCtrl.text = val;
              final inferredState = _getStateForCity(val);
              if (inferredState != null &&
                  _stateCtrl.text.trim().toLowerCase() != inferredState.toLowerCase()) {
                _stateCtrl.text = inferredState;
              }
            });
          }
        },
        validator: (value) {
          if (_cityCtrl.text.trim().isEmpty) {
            return "City is required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildStateDropdown() {
    final states = _stateCities.keys.toList()..sort();
    final currentState = _stateCtrl.text.trim();
    final matched = states.firstWhere(
      (s) => s.toLowerCase() == currentState.toLowerCase(),
      orElse: () => '',
    );
    final matchedState = matched.isNotEmpty ? matched : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
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
              _stateCtrl.text = val;
              // If current city is not part of newly chosen state, switch to first city of that state
              final stateCities = _stateCities[val] ?? [];
              if (!stateCities.any((c) => c.toLowerCase() == _cityCtrl.text.trim().toLowerCase())) {
                _cityCtrl.text = stateCities.isNotEmpty ? stateCities.first : '';
              }
            });
          }
        },
        validator: (value) {
          if (_stateCtrl.text.trim().isEmpty) {
            return "State is required";
          }
          return null;
        },
      ),
    );
  }

  List<String> _getAvailableCities() {
    final state = _stateCtrl.text.trim();
    final matched = _stateCities.keys.firstWhere(
      (k) => k.toLowerCase() == state.toLowerCase(),
      orElse: () => '',
    );
    final matchedKey = matched.isNotEmpty ? matched : null;

    List<String> list;
    if (matchedKey != null) {
      list = List<String>.from(_stateCities[matchedKey]!);
    } else {
      final all = <String>{};
      for (final cities in _stateCities.values) {
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

  String? _getStateForCity(String city) {
    for (final entry in _stateCities.entries) {
      if (entry.value.any((c) => c.toLowerCase() == city.toLowerCase())) {
        return entry.key;
      }
    }
    return null;
  }

  static String? _getStateFromPincode(String pincode) {
    if (pincode.length < 2) return null;
    final prefix = int.tryParse(pincode.substring(0, 2));
    if (prefix == null) return null;

    if (prefix == 11) return "Delhi";
    if (prefix >= 12 && prefix <= 13) return "Haryana";
    if (prefix >= 14 && prefix <= 15) return "Punjab";
    if (prefix == 16) return "Punjab";
    if (prefix == 17) return "Himachal Pradesh";
    if (prefix >= 18 && prefix <= 19) return "Jammu & Kashmir";
    if (prefix >= 20 && prefix <= 28) return "Uttar Pradesh";
    if (prefix >= 30 && prefix <= 34) return "Rajasthan";
    if (prefix >= 36 && prefix <= 39) return "Gujarat";
    if (prefix >= 40 && prefix <= 44) return "Maharashtra";
    if (prefix >= 45 && prefix <= 48) return "Madhya Pradesh";
    if (prefix == 49) return "Chhattisgarh";
    if (prefix == 50) return "Telangana";
    if (prefix >= 51 && prefix <= 53) return "Andhra Pradesh";
    if (prefix >= 56 && prefix <= 59) return "Karnataka";
    if (prefix >= 60 && prefix <= 64) return "Tamil Nadu";
    if (prefix >= 67 && prefix <= 69) return "Kerala";
    if (prefix >= 70 && prefix <= 74) return "West Bengal";
    if (prefix >= 75 && prefix <= 77) return "Odisha";
    if (prefix == 78) return "Assam";
    if (prefix >= 80 && prefix <= 85) return "Bihar";
    return null;
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
                  _cityCtrl.text = newCity;
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

  static const Map<String, List<String>> _stateCities = {
    "Maharashtra": [
      "Nagpur",
      "Mumbai",
      "Pune",
      "Akola",
      "Amravati",
      "Latur",
      "Jalgaon",
      "Nashik",
      "Chhatrapati Sambhaji Nagar",
      "Nanded",
      "Solapur",
      "Ahmednagar",
      "Kolhapur",
      "Sangli",
      "Parbhani",
      "Hingoli",
      "Yavatmal",
      "Wardha",
      "Gondia",
      "Chandrapur",
      "Washim",
      "Buldhana",
      "Dhule",
      "Satara",
      "Thane",
      "Navi Mumbai",
      "Kalyan",
      "Amalner",
    ],
    "Madhya Pradesh": [
      "Indore",
      "Bhopal",
      "Jabalpur",
      "Ujjain",
      "Gwalior",
      "Sagar",
      "Dewas",
      "Satna",
      "Ratlam",
      "Katni",
      "Khandwa",
      "Khargone",
      "Vidisha",
      "Sehore",
      "Hoshangabad",
      "Harda",
      "Betul",
      "Neemuch",
      "Mandsaur",
      "Chhindwara",
      "Damoh",
      "Narsinghpur",
      "Shivpuri",
      "Rewa",
      "Burhanpur",
    ],
    "Gujarat": [
      "Ahmedabad",
      "Surat",
      "Rajkot",
      "Vadodara",
      "Bhavnagar",
      "Jamnagar",
      "Junagadh",
      "Gandhidham",
      "Morbi",
      "Gondal",
      "Unjha",
      "Mehsana",
      "Anand",
      "Nadiad",
      "Bharuch",
      "Himatnagar",
      "Dahod",
      "Amreli",
      "Surendranagar",
      "Porbandar",
      "Navsari",
      "Vapi",
      "Valsad",
      "Gandhinagar",
    ],
    "Rajasthan": [
      "Jaipur",
      "Jodhpur",
      "Kota",
      "Bikaner",
      "Alwar",
      "Sriganganagar",
      "Hanumangarh",
      "Ajmer",
      "Udaipur",
      "Bhilwara",
      "Bharatpur",
      "Baran",
      "Bundi",
      "Tonk",
      "Nagaur",
      "Pali",
      "Jhalawar",
      "Sikar",
      "Churu",
      "Chittorgarh",
    ],
    "Karnataka": [
      "Bengaluru",
      "Hubli",
      "Dharwad",
      "Belagavi",
      "Kalaburagi",
      "Bidar",
      "Raichur",
      "Davanagere",
      "Ballari",
      "Shivamogga",
      "Mysuru",
      "Vijayapura",
      "Bagalkot",
      "Gadag",
      "Yadgir",
    ],
    "Telangana": [
      "Hyderabad",
      "Warangal",
      "Nizamabad",
      "Karimnagar",
      "Khammam",
      "Ramagundam",
      "Mahbubnagar",
      "Nalgonda",
      "Adilabad",
      "Suryapet",
      "Siddipet",
    ],
    "Andhra Pradesh": [
      "Vijayawada",
      "Guntur",
      "Visakhapatnam",
      "Kurnool",
      "Nellore",
      "Rajahmundry",
      "Tirupati",
      "Kakinada",
      "Anantapur",
      "Kadapa",
      "Eluru",
      "Ongole",
      "Vizianagaram",
    ],
    "Uttar Pradesh": [
      "Kanpur",
      "Lucknow",
      "Varanasi",
      "Agra",
      "Meerut",
      "Bareilly",
      "Aligarh",
      "Moradabad",
      "Prayagraj",
      "Gorakhpur",
      "Jhansi",
      "Saharanpur",
      "Muzaffarnagar",
      "Mathura",
      "Hathras",
      "Shahjahanpur",
      "Hapur",
      "Noida",
      "Ghaziabad",
    ],
    "Chhattisgarh": [
      "Raipur",
      "Bilaspur",
      "Durg",
      "Bhilai",
      "Rajnandgaon",
      "Raigarh",
      "Korba",
      "Jagdalpur",
      "Ambikapur",
      "Dhamtari",
      "Mahasamund",
    ],
    "Punjab": [
      "Ludhiana",
      "Amritsar",
      "Jalandhar",
      "Patiala",
      "Bathinda",
      "Khanna",
      "Moga",
      "Abohar",
      "Firozpur",
      "Sangrur",
      "Hoshiarpur",
      "Pathankot",
      "Mohali",
    ],
    "Haryana": [
      "Karnal",
      "Panipat",
      "Ambala",
      "Rohtak",
      "Hisar",
      "Sirsa",
      "Kurukshetra",
      "Jind",
      "Kaithal",
      "Sonipat",
      "Faridabad",
      "Gurugram",
      "Yamunanagar",
      "Rewari",
    ],
    "Delhi": [
      "New Delhi",
      "Delhi",
      "North Delhi",
      "South Delhi",
      "West Delhi",
      "East Delhi",
      "Central Delhi",
    ],
    "Bihar": [
      "Patna",
      "Muzaffarpur",
      "Gaya",
      "Bhagalpur",
      "Purnia",
      "Darbhanga",
      "Begusarai",
      "Samastipur",
      "Katihar",
      "Munger",
      "Chhapra",
      "Arrah",
    ],
    "West Bengal": [
      "Kolkata",
      "Siliguri",
      "Asansol",
      "Durgapur",
      "Howrah",
      "Malda",
      "Burdwan",
      "Kharagpur",
    ],
    "Tamil Nadu": [
      "Chennai",
      "Coimbatore",
      "Madurai",
      "Tiruchirappalli",
      "Salem",
      "Erode",
      "Tirunelveli",
      "Vellore",
      "Thoothukudi",
      "Dindigul",
      "Thanjavur",
      "Tiruppur",
    ],
    "Kerala": [
      "Kochi",
      "Thiruvananthapuram",
      "Kozhikode",
      "Thrissur",
      "Kollam",
      "Palakkad",
      "Alappuzha",
      "Kannur",
    ],
    "Odisha": [
      "Bhubaneswar",
      "Cuttack",
      "Rourkela",
      "Berhampur",
      "Sambalpur",
      "Puri",
      "Balasore",
      "Jharsuguda",
    ],
    "Jharkhand": [
      "Ranchi",
      "Jamshedpur",
      "Dhanbad",
      "Bokaro",
      "Deoghar",
      "Hazaribagh",
      "Giridih",
    ],
    "Assam": [
      "Guwahati",
      "Silchar",
      "Dibrugarh",
      "Jorhat",
      "Nagaon",
      "Tinsukia",
      "Tezpur",
    ],
    "Uttarakhand": [
      "Dehradun",
      "Haridwar",
      "Roorkee",
      "Haldwani",
      "Rudrapur",
      "Kashipur",
      "Rishikesh",
    ],
    "Himachal Pradesh": [
      "Shimla",
      "Solan",
      "Dharamshala",
      "Mandi",
      "Baddi",
      "Kullu",
      "Una",
    ],
    "Goa": [
      "Panaji",
      "Margao",
      "Vasco da Gama",
      "Mapusa",
      "Ponda",
    ],
    "Andaman and Nicobar Islands": [
      "Port Blair",
    ],
    "Arunachal Pradesh": [
      "Itanagar",
      "Naharlagun",
      "Pasighat",
    ],
    "Chandigarh": [
      "Chandigarh",
    ],
    "Dadra and Nagar Haveli and Daman and Diu": [
      "Daman",
      "Diu",
      "Silvassa",
    ],
    "Jammu and Kashmir": [
      "Srinagar",
      "Jammu",
      "Anantnag",
      "Baramulla",
      "Udhampur",
    ],
    "Ladakh": [
      "Leh",
      "Kargil",
    ],
    "Lakshadweep": [
      "Kavaratti",
    ],
    "Manipur": [
      "Imphal",
      "Churachandpur",
      "Thoubal",
    ],
    "Meghalaya": [
      "Shillong",
      "Tura",
      "Jowai",
    ],
    "Mizoram": [
      "Aizawl",
      "Lunglei",
      "Champhai",
    ],
    "Nagaland": [
      "Kohima",
      "Dimapur",
      "Mokokchung",
    ],
    "Puducherry": [
      "Puducherry",
      "Karaikal",
      "Yanam",
      "Mahe",
    ],
    "Sikkim": [
      "Gangtok",
      "Namchi",
      "Gyalshing",
    ],
    "Tripura": [
      "Agartala",
      "Dharmanagar",
      "Udaipur",
    ],
  };
}

