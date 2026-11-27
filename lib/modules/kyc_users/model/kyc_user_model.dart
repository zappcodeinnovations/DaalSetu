class KycUserModel {
  final int id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String mobile;
  final String email;
  final String role;
  final String? panNumber;
  final String? gstNumber;
  final String kycStatus;
  final String? kycSubmittedAt;
  final String? kycApprovedAt;
  final String? kycRejectedAt;
  final String? kycRejectionReason;
  final String accountStatus;
  final String? dateJoined;
  final String? branchName;
  final String? companyName;

  /// The user's primary company location and branch membership (from /api/kyc/list/).
  final String? companyGst;
  final String? country;
  final String? state;
  final String? city;
  final String? fullAddress;
  final String branchStatus;
  final String? branchCode;

  KycUserModel({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    required this.mobile,
    required this.email,
    required this.role,
    required this.panNumber,
    required this.gstNumber,
    required this.kycStatus,
    required this.kycSubmittedAt,
    required this.kycApprovedAt,
    required this.kycRejectedAt,
    required this.kycRejectionReason,
    required this.accountStatus,
    this.dateJoined,
    this.branchName,
    this.companyName,
    this.companyGst,
    this.country,
    this.state,
    this.city,
    this.fullAddress,
    this.branchStatus = 'none',
    this.branchCode,
  });

  factory KycUserModel.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null;
    final company = json['company'] is Map ? Map<String, dynamic>.from(json['company'] as Map) : null;
    final branch = json['branch_membership'] is Map ? Map<String, dynamic>.from(json['branch_membership'] as Map) : null;
    String rawName = (json['name'] ?? '').toString().trim();
    if (rawName.isEmpty) {
      rawName = (json['username'] ?? userObj?['username'] ?? '').toString().trim();
    }

    final first = (json['first_name'] ?? userObj?['first_name'] ?? '').toString().trim();
    final last = (json['last_name'] ?? userObj?['last_name'] ?? '').toString().trim();
    final combinedName = '$first $last'.trim();

    final isDigits = RegExp(r'^\d+$').hasMatch(rawName);
    if ((rawName.isEmpty || isDigits) && combinedName.isNotEmpty) {
      rawName = combinedName;
    }

    final mobile = (json['mobile'] ?? userObj?['mobile'] ?? '').toString().trim();
    final email = (json['email'] ?? userObj?['email'] ?? '').toString().trim();
    final role = (json['role'] ?? userObj?['role'] ?? '').toString().trim();
    final dateJoined = (json['date_joined'] ??
            json['created_at'] ??
            userObj?['date_joined'] ??
            userObj?['created_at'] ??
            json['kyc_submitted_at'] ??
            json['submitted_at'])
        ?.toString();

    return KycUserModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? ''}') ?? 0,
      name: rawName,
      firstName: first.isNotEmpty
          ? first
          : (rawName.isNotEmpty && !isDigits ? rawName.split(' ').first : null),
      lastName: last.isNotEmpty
          ? last
          : (rawName.isNotEmpty && !isDigits && rawName.split(' ').length > 1
              ? rawName.split(' ').sublist(1).join(' ')
              : null),
      mobile: mobile,
      email: email,
      role: role,
      panNumber: json['pan_number']?.toString(),
      gstNumber: json['gst_number']?.toString(),
      kycStatus: (json['kyc_status'] ?? '').toString().trim(),
      kycSubmittedAt: (json['kyc_submitted_at'] ?? json['submitted_at'])?.toString(),
      kycApprovedAt: (json['kyc_approved_at'] ?? json['approved_at'])?.toString(),
      kycRejectedAt: (json['kyc_rejected_at'] ?? json['rejected_at'])?.toString(),
      kycRejectionReason: (json['kyc_rejection_reason'] ?? json['rejection_reason'])?.toString(),
      accountStatus: (json['account_status'] ?? (json['is_active'] == true ? 'active' : (json['is_active'] == false ? 'inactive' : ''))).toString().trim(),
      dateJoined: dateJoined,
      branchName: json['branch_name']?.toString(),
      companyName: (json['company_name'] ?? company?['legal_name'])?.toString(),
      companyGst: company?['gst_number']?.toString(),
      country: company?['country']?.toString(),
      state: company?['state']?.toString(),
      city: company?['city']?.toString(),
      fullAddress: company?['address']?.toString(),
      branchStatus: (branch?['status'] ?? 'none').toString(),
      branchCode: branch?['branch_code']?.toString(),
    );
  }

  int get kycScore {
    int score = 20; // Base score for registration
    if (kycStatus.toLowerCase() == 'approved') {
      score = 100;
    } else {
      if (email.isNotEmpty) score += 10;
      if (mobile.isNotEmpty) score += 20;
      if (panNumber != null && panNumber!.isNotEmpty) score += 25;
      if (gstNumber != null && gstNumber!.isNotEmpty) score += 25;
      if (score > 95) score = 95; // Leave it slightly below 100 if pending
    }
    return score;
  }
}
