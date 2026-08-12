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

  final String kycStatus;
  final String? kycSubmittedAt;
  final String? kycApprovedAt;
  final String? kycRejectedAt;
  final String? kycRejectionReason;

  final String accountStatus;
  final bool isActive;

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
    required this.kycStatus,
    this.kycSubmittedAt,
    this.kycApprovedAt,
    this.kycRejectedAt,
    this.kycRejectionReason,
    required this.accountStatus,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? "",
      mobile: json['mobile'] ?? "",
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'] ?? "",

      tags: (json['tags'] as List? ?? []).map((e) => Tag.fromJson(e)).toList(),
      panNumber: json['pan_number'],
      gstNumber: json['gst_number'],

      profileImage: json['profile_image'],
      gender: json['gender'],
      dob: json['dob'],

      panImage: json['pan_image'],
      gstImage: json['gst_image'],

      kycStatus: json['kyc_status'] ?? "",
      kycSubmittedAt: json['kyc_submitted_at'],
      kycApprovedAt: json['kyc_approved_at'],
      kycRejectedAt: json['kyc_rejected_at'],
      kycRejectionReason: json['kyc_rejection_reason'],

      accountStatus: json['account_status'] ?? "",
      isActive: json['is_active'] ?? false,
    );
  }

  String get fullName {
    return "${firstName ?? ""} ${lastName ?? ""}".trim();
  }
}
