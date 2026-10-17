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

  ProfileModel copyWith({
    int? id,
    String? username,
    String? mobile,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? panNumber,
    String? gstNumber,
    String? profileImage,
    String? gender,
    String? dob,
    String? panImage,
    String? gstImage,
    String? aadhaarImage,
    String? kycStatus,
    String? accountStatus,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      panNumber: panNumber ?? this.panNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      profileImage: profileImage ?? this.profileImage,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      panImage: panImage ?? this.panImage,
      gstImage: gstImage ?? this.gstImage,
      aadhaarImage: aadhaarImage ?? this.aadhaarImage,
      kycStatus: kycStatus ?? this.kycStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      isActive: isActive ?? this.isActive,
    );
  }

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

    String extractDoc(List<String> keys) {
      for (final key in keys) {
        final val = data[key];
        if (val != null && val.toString().trim().isNotEmpty && val.toString() != 'null') {
          return val.toString().trim();
        }
      }
      for (final parent in ['documents', 'kyc_documents', 'kyc', 'company']) {
        if (data[parent] is Map) {
          final sub = data[parent] as Map;
          for (final key in keys) {
            final val = sub[key];
            if (val != null && val.toString().trim().isNotEmpty && val.toString() != 'null') {
              return val.toString().trim();
            }
          }
        }
      }
      return "";
    }

    final rawDob = data["dob"] ?? data["date_of_birth"];
    final String parsedDob = (rawDob == null || rawDob.toString() == 'null')
        ? ""
        : rawDob.toString().trim();

    final rawEmail = data["email"] ?? data["user_email"];
    final String parsedEmail = (rawEmail == null || rawEmail.toString() == 'null')
        ? ""
        : rawEmail.toString().trim();

    final rawMobile = data["mobile"] ?? data["phone"] ?? data["phone_number"] ?? data["username"];
    final String parsedMobile = (rawMobile == null || rawMobile.toString() == 'null')
        ? ""
        : rawMobile.toString().trim();

    return ProfileModel(
      id: parsedId,
      username: data["username"]?.toString() ?? "",
      mobile: parsedMobile,
      email: parsedEmail,
      firstName: data["first_name"]?.toString() ?? "",
      lastName: data["last_name"]?.toString() ?? "",
      role: data["role"]?.toString() ?? "",
      panNumber: data["pan_number"]?.toString() ?? "",
      gstNumber: data["gst_number"]?.toString() ?? "",
      profileImage: data["profile_image"]?.toString(),
      gender: data["gender"]?.toString() ?? "",
      dob: parsedDob,
      panImage: extractDoc([
        "pan_card_upload",
        "pan_image",
        "pan_card",
        "pan_document",
        "pan_card_image",
        "pan_file",
        "pan_url",
      ]),
      gstImage: extractDoc([
        "gst_certificate_upload",
        "gst_image",
        "gst_certificate",
        "gst_document",
        "gst_certificate_image",
        "gst_file",
        "gst_url",
      ]),
      aadhaarImage: extractDoc([
        "adhar_front_upload",
        "adharcard_image",
        "aadhaar_image",
        "aadhaar_front_image",
        "aadhaar_card",
        "aadhar_image",
        "aadhaar_document",
        "aadhaar_file",
        "aadhaar_url",
      ]),
      kycStatus: data["kyc_status"] ?? "",
      accountStatus: data["account_status"] ?? "",
      isActive: data["is_active"] ?? false,
    );
  }
}
