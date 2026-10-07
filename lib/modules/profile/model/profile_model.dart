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
  final String aadhaarImage;
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
    required this.aadhaarImage,
    required this.kycStatus,
    required this.accountStatus,
    required this.isActive,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data = json;
    if (data.containsKey('body') && data['body'] is Map<String, dynamic>) {
      data = data['body'] as Map<String, dynamic>;
    }
    if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
      data = data['data'] as Map<String, dynamic>;
    }

    final idVal = data["id"];
    final int parsedId = idVal is int
        ? idVal
        : (idVal != null ? int.tryParse(idVal.toString()) ?? 0 : 0);

    return ProfileModel(
      id: parsedId,
      username: data["username"] ?? "",
      mobile: data["mobile"] ?? "",
      email: data["email"] ?? "",
      firstName: data["first_name"] ?? "",
      lastName: data["last_name"] ?? "",
      role: data["role"] ?? "",
      panNumber: data["pan_number"] ?? "",
      gstNumber: data["gst_number"] ?? "",
      profileImage: data["profile_image"],
      gender: data["gender"] ?? "",
      dob: data["dob"] ?? "",
      panImage: data["pan_image"] ?? "",
      gstImage: data["gst_image"] ?? "",
      aadhaarImage: data["adharcard_image"] ?? "",
      kycStatus: data["kyc_status"] ?? "",
      accountStatus: data["account_status"] ?? "",
      isActive: data["is_active"] ?? false,
    );
  }
}
