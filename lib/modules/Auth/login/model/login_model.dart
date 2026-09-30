class LoginUser {
  final int id;
  final String username;
  final String role;
  final String kycStatus;
  final String status;
  final String accountStatus;
  final int? activeBranchId;
  final String? activeBranchCode;

  LoginUser({
    required this.id,
    required this.username,
    required this.role,
    required this.kycStatus,
    required this.status,
    required this.accountStatus,
    this.activeBranchId,
    this.activeBranchCode,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json["id"] as int,
      username: json["username"] as String? ?? "",
      role: json["role"] as String? ?? "",
      kycStatus: json["kyc_status"] as String? ?? "",
      status: json["status"] as String? ?? "",
      accountStatus: json["account_status"] as String? ?? "",
      activeBranchId: json["active_branch_id"] as int?,
      activeBranchCode: json["active_branch_code"] as String?,
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
      access: json["access"] as String,
      refresh: json["refresh"] as String,
      user: LoginUser.fromJson(json["user"] as Map<String, dynamic>),
    );
  }
}
