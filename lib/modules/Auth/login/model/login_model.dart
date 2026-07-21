class LoginUser {
  final int id;
  final String username;
  final String role;
  final String kycStatus;
  final String accountStatus;

  LoginUser({
    required this.id,
    required this.username,
    required this.role,
    required this.kycStatus,
    required this.accountStatus,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json["id"],
      username: json["username"],
      role: json["role"],
      kycStatus: json["kyc_status"],
      accountStatus: json["account_status"],
    );
  }
}
class LoginResponse {
  final String access;
  final String refresh;
  final LoginUser user;

  LoginResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      access: json["access"],
      refresh: json["refresh"],
      user: LoginUser.fromJson(json["user"]),
    );
  }
}
