class RbacSubAdminModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String branchRefCode;
  final String company;
  final List<String> roles;
  final bool isActive;
  final String createdAt;

  RbacSubAdminModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.branchRefCode,
    required this.company,
    required this.roles,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName {
    final names = [firstName, lastName].where((s) => s.trim().isNotEmpty).join(' ');
    if (names.isNotEmpty) return names;
    if (email.isNotEmpty) return email;
    return mobile.isNotEmpty ? mobile : "Sub Admin #$id";
  }

  factory RbacSubAdminModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    String parseCompany(dynamic val) {
      if (val is String) return val;
      if (val is Map) return val['legal_name']?.toString() ?? val['name']?.toString() ?? '';
      return '';
    }

    List<String> parseRoles(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map) return e['name']?.toString() ?? e['role_name']?.toString() ?? e.toString();
          return e.toString();
        }).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        return [raw];
      }
      return [];
    }

    return RbacSubAdminModel(
      id: parseId(json['id'] ?? json['user_id']),
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? json['username']?.toString() ?? '',
      branchRefCode: json['branch_ref_code']?.toString() ??
          json['branch_code']?.toString() ??
          (json['branch'] is Map ? json['branch']['branch_code']?.toString() ?? '' : ''),
      company: parseCompany(json['company'] ?? json['company_name'] ?? json['legal_name']),
      roles: parseRoles(json['roles'] ?? json['role_names'] ?? json['role_list'] ?? json['role']),
      isActive: json['is_active'] == true || json['active'] == true || json['status']?.toString().toLowerCase() == 'active',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
