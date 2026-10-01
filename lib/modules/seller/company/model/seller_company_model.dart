class SellerCompanyModel {
  final int id;
  final bool isPrimary;
  final String legalName;
  final String companyType;
  final int yearOfEstablishment;
  final int? numberOfEmployees;
  final String gstNumber;
  final String panNumber;
  final String addressLine1;
  final String addressLine2;
  final String state;
  final String city;
  final String pincode;
  final String country;
  final String landmark;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerCompanyModel({
    required this.id,
    required this.isPrimary,
    required this.legalName,
    required this.companyType,
    required this.yearOfEstablishment,
    this.numberOfEmployees,
    required this.gstNumber,
    required this.panNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.state,
    required this.city,
    required this.pincode,
    required this.country,
    required this.landmark,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerCompanyModel.fromJson(Map<String, dynamic> json) {
    return SellerCompanyModel(
      id: json['id'],
      isPrimary: json['is_primary'] ?? false,
      legalName: json['legal_name'] ?? "",
      companyType: json['company_type'] ?? "",
      yearOfEstablishment: json['year_of_establishment'] ?? 0,
      numberOfEmployees: json['number_of_employees'],
      gstNumber: json['gst_number'] ?? "",
      panNumber: json['pan_number'] ?? "",
      addressLine1: json['address_line_1'] ?? "",
      addressLine2: json['address_line_2'] ?? "",
      state: json['state'] ?? "",
      city: json['city'] ?? "",
      pincode: json['pincode'] ?? "",
      country: json['country'] ?? "",
      landmark: json['landmark'] ?? "",
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legal_name': legalName,
      'company_type': companyType,
      'year_of_establishment': yearOfEstablishment,
      'gst_number': gstNumber,
      'pan_number': panNumber,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'state': state,
      'city': city,
      'pincode': pincode,
      'country': country,
      'landmark': landmark,
    };
  }
}
