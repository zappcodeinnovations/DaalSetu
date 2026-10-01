class BranchModel {
  final int id;
  final String locationName;
  final String state;
  final String city;
  final String area;
  final bool isActive;
  final String? branchCode;

  BranchModel({
    required this.id,
    required this.locationName,
    required this.state,
    required this.city,
    required this.area,
    required this.isActive,
    this.branchCode,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? 0,
      locationName: json['location_name'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      isActive: json['is_active'] ?? false,
      branchCode: json['branch_code'],
    );
  }
}
