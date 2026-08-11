class AssignedVehicle {
  final int id;
  final String vehicleNumber;
  final String vehicleStatus;
  final String vehicleStatusDisplay;

  AssignedVehicle({
    required this.id,
    required this.vehicleNumber,
    required this.vehicleStatus,
    required this.vehicleStatusDisplay,
  });

  factory AssignedVehicle.fromJson(Map<String, dynamic> json) {
    return AssignedVehicle(
      id: json['id'] ?? 0,
      vehicleNumber: json['vehicle_number'] ?? '',
      vehicleStatus: json['vehicle_status'] ?? '',
      vehicleStatusDisplay: json['vehicle_status_display'] ?? '',
    );
  }
}

class DriverModel {
  final int id;
  final String driverName;
  final String phoneNumber;
  final String email;
  final String licenseNumber;
  final String? licenseExpiry;
  final int? experience;
  final String? address;
  final String status;
  final String statusDisplay;
  final String assignmentStatus;
  final String assignmentStatusDisplay;
  final AssignedVehicle? assignedVehicle;

  DriverModel({
    required this.id,
    required this.driverName,
    required this.phoneNumber,
    required this.email,
    required this.licenseNumber,
    this.licenseExpiry,
    this.experience,
    this.address,
    required this.status,
    required this.statusDisplay,
    required this.assignmentStatus,
    required this.assignmentStatusDisplay,
    this.assignedVehicle,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? 0,
      driverName: json['driver_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      licenseExpiry: json['license_expiry'],
      experience: json['experience'],
      address: json['address'],
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      assignmentStatus: json['assignment_status'] ?? '',
      assignmentStatusDisplay: json['assignment_status_display'] ?? '',
      assignedVehicle: json['assigned_vehicle'] != null
          ? AssignedVehicle.fromJson(json['assigned_vehicle'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_name': driverName,
      'phone_number': phoneNumber,
      'email': email,
      'license_number': licenseNumber,
      'license_expiry': licenseExpiry,
      'experience': experience,
      'address': address,
      'status': status,
    }..removeWhere((key, value) => value == null || value == '');
  }
}
