class UserModel {
  final int id;
  final String username;
  final String mobile;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String panNumber;
  final String gstNumber;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.mobile,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.panNumber,
    required this.gstNumber,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      username: json["username"],
      mobile: json["mobile"],
      email: json["email"],
      firstName: json["first_name"],
      lastName: json["last_name"],
      role: json["role"],
      panNumber: json["pan_number"] ?? "",
      gstNumber: json["gst_number"] ?? "",
      isActive: json["is_active"] ?? false,
    );
  }
}
