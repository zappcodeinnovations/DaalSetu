class KycUserModel {
  final int id;
  final String name;
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

  KycUserModel({
    required this.id,
    required this.name,
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
  });

  factory KycUserModel.fromJson(Map<String, dynamic> json) {
    return KycUserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      panNumber: json['pan_number'],
      gstNumber: json['gst_number'],
      kycStatus: json['kyc_status'] ?? '',
      kycSubmittedAt: json['kyc_submitted_at'],
      kycApprovedAt: json['kyc_approved_at'],
      kycRejectedAt: json['kyc_rejected_at'],
      kycRejectionReason: json['kyc_rejection_reason'],
      accountStatus: json['account_status'] ?? '',
    );
  }
}
