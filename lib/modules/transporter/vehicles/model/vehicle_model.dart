class VehicleModel {
  final int id;
  final String vehicleNumber;
  final String vehicleType;
  final String vehicleBrand;
  final String vehicleBrandDisplay;
  final String? modelName;
  final int? manufacturingYear;
  final String fuelType;
  final String loadCapacityTons;
  final String bodyType;
  final String bodyTypeDisplay;
  final int? numberOfAxles;
  
  final String? rcNumber;
  final String? insuranceNumber;
  final String? insuranceExpiryDate;
  final String? permitType;
  final String? permitTypeDisplay;
  final String? permitExpiryDate;

  final String vehicleStatus;
  final String vehicleStatusDisplay;
  
  final String? vehicleBrandOther;
  final String? bodyTypeOther;
  final String? permitTypeOther;
  final String? lengthFt;
  final String? widthFt;
  final String? heightFt;
  final String? rcUploadUrl;

  final int? assignedDriver;
  final String? assignedDriverName;
  final String? driverPhoneNumber;

  VehicleModel({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleBrand,
    required this.vehicleBrandDisplay,
    this.modelName,
    this.manufacturingYear,
    required this.fuelType,
    required this.loadCapacityTons,
    required this.bodyType,
    required this.bodyTypeDisplay,
    this.numberOfAxles,
    this.rcNumber,
    this.insuranceNumber,
    this.insuranceExpiryDate,
    this.permitType,
    this.permitTypeDisplay,
    this.permitExpiryDate,
    required this.vehicleStatus,
    required this.vehicleStatusDisplay,
    this.vehicleBrandOther,
    this.bodyTypeOther,
    this.permitTypeOther,
    this.lengthFt,
    this.widthFt,
    this.heightFt,
    this.rcUploadUrl,
    this.assignedDriver,
    this.assignedDriverName,
    this.driverPhoneNumber,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      vehicleBrand: json['vehicle_brand'] ?? '',
      vehicleBrandDisplay: json['vehicle_brand_display'] ?? '',
      modelName: json['model_name'],
      manufacturingYear: json['manufacturing_year'],
      fuelType: json['fuel_type'] ?? '',
      loadCapacityTons: json['load_capacity_tons']?.toString() ?? '',
      bodyType: json['body_type'] ?? '',
      bodyTypeDisplay: json['body_type_display'] ?? '',
      numberOfAxles: json['number_of_axles'],
      rcNumber: json['rc_number'],
      insuranceNumber: json['insurance_number'],
      insuranceExpiryDate: json['insurance_expiry_date'],
      permitType: json['permit_type'],
      permitTypeDisplay: json['permit_type_display'],
      permitExpiryDate: json['permit_expiry_date'],
      vehicleStatus: json['vehicle_status'] ?? '',
      vehicleStatusDisplay: json['vehicle_status_display'] ?? '',
      vehicleBrandOther: json['vehicle_brand_other'],
      bodyTypeOther: json['body_type_other'],
      permitTypeOther: json['permit_type_other'],
      lengthFt: json['length_ft']?.toString(),
      widthFt: json['width_ft']?.toString(),
      heightFt: json['height_ft']?.toString(),
      rcUploadUrl: (json['rc_upload_url'] ?? '').toString().isEmpty ? null : json['rc_upload_url'].toString(),
      assignedDriver: json['assigned_driver'],
      // Driver profile assignments are mirrored into driver_name; assigned_driver_name is the legacy user link.
      assignedDriverName: _nonEmpty(json['driver_name']) ?? _nonEmpty(json['assigned_driver_name']),
      driverPhoneNumber: _nonEmpty(json['driver_phone_number']),
    );
  }

  static String? _nonEmpty(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  bool get hasDriver => (assignedDriverName ?? '').isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'vehicle_brand': vehicleBrand,
      'model_name': modelName,
      'manufacturing_year': manufacturingYear,
      'fuel_type': fuelType,
      'load_capacity_tons': loadCapacityTons,
      'body_type': bodyType,
      'number_of_axles': numberOfAxles,
      'rc_number': rcNumber,
      'insurance_number': insuranceNumber,
      'insurance_expiry_date': insuranceExpiryDate,
      'permit_type': permitType,
      'permit_expiry_date': permitExpiryDate,
      'vehicle_status': vehicleStatus,
    }..removeWhere((key, value) => value == null || value == '');
  }
}
