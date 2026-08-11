class CompanyModel {
  final int id;
  final String legalName;
  final bool isPrimary;
  
  // Detailed fields
  final String? companyType;
  final int? yearOfEstablishment;
  final int? numberOfEmployees;
  final String? gstNumber;
  final String? panNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? state;
  final String? city;
  final String? pincode;
  final String? country;
  final String? landmark;
  final bool? isVerified;

  CompanyModel({
    required this.id,
    required this.legalName,
    required this.isPrimary,
    this.companyType,
    this.yearOfEstablishment,
    this.numberOfEmployees,
    this.gstNumber,
    this.panNumber,
    this.addressLine1,
    this.addressLine2,
    this.state,
    this.city,
    this.pincode,
    this.country,
    this.landmark,
    this.isVerified,
  });

  // Factory for parsing from the dropdown list API
  factory CompanyModel.fromDropdownJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? 0,
      legalName: json['legal_name'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }

  // Factory for parsing the full detail API
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? 0,
      legalName: json['legal_name'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      companyType: json['company_type'],
      yearOfEstablishment: json['year_of_establishment'],
      numberOfEmployees: json['number_of_employees'],
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      state: json['state'],
      city: json['city'],
      pincode: json['pincode'],
      country: json['country'],
      landmark: json['landmark'],
      isVerified: json['is_verified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'legal_name': legalName,
      'company_type': companyType,
      'year_of_establishment': yearOfEstablishment,
      'number_of_employees': numberOfEmployees,
      'gst_number': gstNumber,
      'pan_number': panNumber,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'state': state,
      'city': city,
      'pincode': pincode,
      'country': country,
      'landmark': landmark,
    }..removeWhere((key, value) => value == null);
  }
}
