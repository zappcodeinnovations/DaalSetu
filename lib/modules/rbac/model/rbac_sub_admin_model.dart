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
      if (val is String && val.trim().isNotEmpty) return val;
      if (val is Map) return val['legal_name']?.toString() ?? val['name']?.toString() ?? val['company_name']?.toString() ?? '';
      return '';
    }

    List<String> parseRoles(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map) return e['name']?.toString() ?? e['role_name']?.toString() ?? e['label']?.toString() ?? e.toString();
          return e.toString();
        }).where((s) => s.trim().isNotEmpty && s != 'sub_admin').toList();
      }
      if (raw is String && raw.isNotEmpty && raw != 'sub_admin') {
        return [raw];
      }
      return [];
    }

    final rawRoles = json['roles'] ??
        json['role_names'] ??
        json['role_list'] ??
        json['role_name'] ??
        json['assigned_roles'] ??
        json['groups'];

    var rolesList = parseRoles(rawRoles);
    if (rolesList.isEmpty && json['role'] != null) {
      final rStr = json['role'].toString();
      if (rStr != 'sub_admin' && rStr.isNotEmpty) {
        rolesList = [rStr];
      }
    }

    String fName = json['first_name']?.toString() ?? json['firstName']?.toString() ?? '';
    String lName = json['last_name']?.toString() ?? json['lastName']?.toString() ?? '';
    if (fName.isEmpty && json['name'] != null) {
      final nameParts = json['name'].toString().trim().split(' ');
      fName = nameParts.first;
      if (nameParts.length > 1) {
        lName = nameParts.sublist(1).join(' ');
      }
    }
    if (fName.isEmpty && json['full_name'] != null) {
      final nameParts = json['full_name'].toString().trim().split(' ');
      fName = nameParts.first;
      if (nameParts.length > 1) {
        lName = nameParts.sublist(1).join(' ');
      }
    }

    return RbacSubAdminModel(
      id: parseId(json['id'] ?? json['user_id'] ?? json['pk']),
      firstName: fName,
      lastName: lName,
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? json['username']?.toString() ?? json['contact_number']?.toString() ?? '',
      branchRefCode: json['branch_ref_code']?.toString() ??
          json['branch_code']?.toString() ??
          json['branchRefCode']?.toString() ??
          (json['branch'] is Map ? json['branch']['branch_code']?.toString() ?? '' : ''),
      company: parseCompany(json['company'] ?? json['company_name'] ?? json['legal_name'] ?? json['registered_company']),
      roles: rolesList,
      isActive: json['is_active'] == true ||
          json['active'] == true ||
          json['status']?.toString().toLowerCase() == 'active' ||
          json['account_status']?.toString().toLowerCase() == 'active',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'name': fullName,
        'email': email,
        'mobile': mobile,
        'branch_ref_code': branchRefCode,
        'company': company,
        'roles': roles,
        'is_active': isActive,
        'created_at': createdAt,
      };

  RbacSubAdminModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    String? branchRefCode,
    String? company,
    List<String>? roles,
    bool? isActive,
    String? createdAt,
  }) {
    return RbacSubAdminModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      branchRefCode: branchRefCode ?? this.branchRefCode,
      company: company ?? this.company,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

