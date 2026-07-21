class ForgotPasswordRequestModel {
  final String email;

  ForgotPasswordRequestModel({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
    };
  }
}
class ForgotPasswordResponseModel {
  final String message;

  ForgotPasswordResponseModel({
    required this.message,
  });

  factory ForgotPasswordResponseModel.fromJson(
      Map<String, dynamic> json) {
    return ForgotPasswordResponseModel(
      message: json["message"] ?? "",
    );
  }
}
