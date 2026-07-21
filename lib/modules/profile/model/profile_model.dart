class ProfileModel {
  final int id;
  final String username;
  final String mobile;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String panNumber;
  final String gstNumber;
  final String? profileImage;
  final String gender;
  final String dob;
  final String panImage;
  final String gstImage;
  final String kycStatus;
  final String accountStatus;
  final bool isActive;

  ProfileModel({
    required this.id,
    required this.username,
    required this.mobile,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.panNumber,
    required this.gstNumber,
    required this.profileImage,
    required this.gender,
    required this.dob,
    required this.panImage,
    required this.gstImage,
    required this.kycStatus,
    required this.accountStatus,
    required this.isActive,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json["id"],
      username: json["username"] ?? "",
      mobile: json["mobile"] ?? "",
      email: json["email"] ?? "",
      firstName: json["first_name"] ?? "",
      lastName: json["last_name"] ?? "",
      role: json["role"] ?? "",
      panNumber: json["pan_number"] ?? "",
      gstNumber: json["gst_number"] ?? "",
      profileImage: json["profile_image"],
      gender: json["gender"] ?? "",
      dob: json["dob"] ?? "",
      panImage: json["pan_image"] ?? "",
      gstImage: json["gst_image"] ?? "",
      kycStatus: json["kyc_status"] ?? "",
      accountStatus: json["account_status"] ?? "",
      isActive: json["is_active"] ?? false,
    );
  }
}
