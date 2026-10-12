import './tag_model.dart';

class UserModel {
  final int id;
  final String username;
  final String mobile;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String role;

  final List<Tag> tags;
  final String? panNumber;
  final String? gstNumber;

  final String? profileImage;
  final String? gender;
  final String? dob;

  final String? panImage;
  final String? gstImage;
  final String? aadharFrontImage;
  final String? aadharBackImage;

  final String kycStatus;
  final String? kycSubmittedAt;
  final String? kycApprovedAt;
  final String? kycRejectedAt;
  final String? kycRejectionReason;

  final String accountStatus;
  final bool isActive;

  // Additional fields for web admin panel parity
  final String? companyName;
  final String? brand;
  final String? branchCodes;
  final String? plainPassword;
  final String? parentAdmin;
  final String? customRoles;
  final String? registrationReason;
  final String? dateJoined;
  final Map<String, dynamic> rawJson;

  UserModel({
    required this.id,
    required this.username,
    required this.mobile,
    this.email,
    this.firstName,
    this.lastName,
    required this.tags,
    required this.role,
    this.panNumber,
    this.gstNumber,
    this.profileImage,
    this.gender,
    this.dob,
    this.panImage,
    this.gstImage,
    this.aadharFrontImage,
    this.aadharBackImage,
    required this.kycStatus,
    this.kycSubmittedAt,
    this.kycApprovedAt,
    this.kycRejectedAt,
    this.kycRejectionReason,
    required this.accountStatus,
    required this.isActive,
    this.companyName,
    this.brand,
    this.branchCodes,
    this.plainPassword,
    this.parentAdmin,
    this.customRoles,
    this.registrationReason,
    this.dateJoined,
    this.rawJson = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? extractString(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        final s = val.trim();
        return (s.isEmpty || s == 'null') ? null : s;
      }
      if (val is Map) {
        return (val['name'] ??
                val['company_name'] ??
                val['title'] ??
                val['code'] ??
                val['username'])
            ?.toString();
      }
      if (val is List) {
        final items = val
            .map((e) => e is Map
                ? (e['name'] ?? e['title'] ?? e['code'] ?? '')
                : e.toString())
            .where((s) => s.toString().trim().isNotEmpty)
            .join(', ');
        return items.isEmpty ? null : items;
      }
      return val.toString();
    }

    String? extractDoc(List<String> keys) {
      for (final key in keys) {
        final val = json[key];
        if (val != null &&
            val.toString().trim().isNotEmpty &&
            val.toString() != 'null') {
          return val.toString().trim();
        }
      }
      for (final parent in ['documents', 'kyc_documents', 'kyc', 'company']) {
        if (json[parent] is Map) {
          final sub = json[parent] as Map;
          for (final key in keys) {
            final val = sub[key];
            if (val != null &&
                val.toString().trim().isNotEmpty &&
                val.toString() != 'null') {
              return val.toString().trim();
            }
          }
        }
      }
      return null;
    }

    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ??
          json['name']?.toString() ??
          "",
      mobile: json['mobile']?.toString() ??
          json['phone']?.toString() ??
          "",
      email: json['email']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      role: json['role']?.toString() ??
          json['user_role']?.toString() ??
          (json['roles'] != null ? extractString(json['roles']) ?? "" : ""),

      tags: (json['tags'] as List? ?? []).map((e) => Tag.fromJson(e)).toList(),
      panNumber: json['pan_number']?.toString() ??
          json['pan_no']?.toString() ??
          json['pan']?.toString(),
      gstNumber: json['gst_number']?.toString() ??
          json['gst_no']?.toString() ??
          json['gstin']?.toString() ??
          json['gst']?.toString(),

      profileImage: json['profile_image']?.toString() ??
          json['avatar']?.toString() ??
          json['image']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString() ?? json['date_of_birth']?.toString(),

      panImage: extractDoc([
        'pan_image',
        'pan_card_upload',
        'pan_card',
        'pan_document',
        'pan_card_image',
        'pan_file',
      ]),
      gstImage: extractDoc([
        'gst_image',
        'gst_certificate_upload',
        'gst_cert',
        'gst_certificate',
        'gst_document',
        'gst_certificate_image',
        'gst_file',
      ]),
      aadharFrontImage: extractDoc([
        'aadhar_front_image',
        'adhar_front_upload',
        'adharcard_image',
        'adhar_card',
        'aadhar_image',
        'aadhar_front',
        'aadhaar_front',
      ]),
      aadharBackImage: extractDoc([
        'aadhar_back_image',
        'adhar_back_upload',
        'aadhar_back',
        'aadhaar_back',
      ]),

      kycStatus: json['kyc_status']?.toString() ??
          json['status']?.toString() ??
          "",
      kycSubmittedAt: json['kyc_submitted_at']?.toString(),
      kycApprovedAt: json['kyc_approved_at']?.toString(),
      kycRejectedAt: json['kyc_rejected_at']?.toString(),
      kycRejectionReason: json['kyc_rejection_reason']?.toString() ??
          json['rejection_reason']?.toString() ??
          json['suspension_reason']?.toString(),

      accountStatus: json['account_status']?.toString() ??
          json['status']?.toString() ??
          "",
      isActive: json['is_active'] == true ||
          json['status']?.toString().toLowerCase() == 'active',

      companyName: extractString(json['company_name'] ?? json['company']),
      brand: extractString(json['brand'] ?? json['brand_name'] ?? json['brands']),
      branchCodes: extractString(json['branch_codes'] ??
          json['branch_code'] ??
          json['branch'] ??
          json['branches']),
      plainPassword: extractString(json['plain_password'] ??
          json['password'] ??
          json['user_password'] ??
          json['plainPassword']),
      parentAdmin: extractString(json['parent_admin_name'] ??
          json['parent_admin'] ??
          json['under_admin']),
      customRoles: extractString(json['custom_roles'] ??
          json['custom_role'] ??
          json['roles'] ??
          json['access_role_ids']),
      registrationReason: extractString(
          json['registration_reason'] ?? json['reason']),
      dateJoined: extractString(
          json['date_joined'] ?? json['created_at'] ?? json['registered_at']),
      rawJson: json,
    );
  }

  String get fullName {
    final combined = "${firstName ?? ""} ${lastName ?? ""}".trim();
    if (combined.isNotEmpty) return combined;
    if (rawJson['name'] != null &&
        rawJson['name'].toString().trim().isNotEmpty) {
      return rawJson['name'].toString().trim();
    }
    return username;
  }
}
