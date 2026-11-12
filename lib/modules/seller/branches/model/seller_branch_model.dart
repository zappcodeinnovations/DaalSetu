class SellerBranchModel {
  final int? id;
  final int? branchId;
  final String? branchCode;
  final String? locationName;
  final String? city;
  final String? state;
  final String? area;
  final bool? isPrimary;
  final String? status;
  final String? adminName;
  final String? userName;

  SellerBranchModel({
    this.id,
    this.branchId,
    this.branchCode,
    this.locationName,
    this.city,
    this.state,
    this.area,
    this.isPrimary,
    this.status,
    this.adminName,
    this.userName,
  });

  factory SellerBranchModel.fromJson(Map<String, dynamic> json) {
    return SellerBranchModel(
      id: json['id'] as int?,
      // Pending requests carry their own id plus branch_id; branch rows only have id.
      branchId: json['branch_id'] is int ? json['branch_id'] as int : json['id'] as int?,
      branchCode: json['branch_code'] ?? json['code'],
      locationName: json['location_name'] ?? json['name'] ?? json['city'],
      city: json['city'],
      state: json['state'],
      area: json['area'],
      isPrimary: json['is_primary'] as bool? ?? false,
      status: json['status'] ?? 'active',
      adminName: json['admin_name']?.toString() ??
          (json['admin'] is String
              ? json['admin'].toString()
              : (json['admin'] is Map
                  ? (json['admin']['name'] ?? json['admin']['username'] ?? json['admin']['email'])?.toString()
                  : null)) ??
          json['manager']?.toString() ??
          json['contact_person']?.toString(),
      userName: json['user_name']?.toString() ??
          (json['user'] is String
              ? json['user'].toString()
              : (json['user'] is Map
                  ? (json['user']['name'] ?? json['user']['username'] ?? json['user']['email'])?.toString()
                  : null)) ??
          json['creator_name']?.toString() ??
          json['created_by_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_code': branchCode,
      'location_name': locationName,
      'city': city,
      'state': state,
      'area': area,
      'is_primary': isPrimary,
      'status': status,
      'admin_name': adminName,
      'user_name': userName,
    };
  }
}
