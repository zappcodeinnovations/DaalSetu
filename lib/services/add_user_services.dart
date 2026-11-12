import 'dart:io';
import '../network/api_client.dart';
import '../comman/api_url.dart';

class AddUserServices {
  static Future<Map<String, dynamic>> addUser({
    required String mobile,
    required String email,
    required String firstName,
    String? lastName,
    required String role,
    required String password,
    String? branchCode,
    String? panNumber,
    String? gstNumber,
    String? gender,
    String? dob,
    File? panImage,
    File? gstImage,
    int? tagId,
  }) async {
    Map<String, String> fields = {
      "mobile": mobile,
      "email": email,
      "first_name": firstName,
      "role": role,
      "password": password,
    };

    if (lastName != null && lastName.isNotEmpty) fields["last_name"] = lastName;
    if (branchCode != null && branchCode.isNotEmpty) fields["branch_code"] = branchCode;
    if (panNumber != null && panNumber.isNotEmpty) fields["pan_number"] = panNumber;
    if (gstNumber != null && gstNumber.isNotEmpty) fields["gst_number"] = gstNumber;
    if (gender != null && gender.isNotEmpty) fields["gender"] = gender;
    if (dob != null && dob.isNotEmpty) fields["dob"] = dob;

    Map<String, String> files = {};

    if (panImage != null) {
      files["pan_image"] = panImage.path;
    }

    if (gstImage != null) {
      files["gst_image"] = gstImage.path;
    }

    final response = await ApiClient.postMultipart(
      endpoint: ApiUrls.addUser, // "/api/adduser/"
      fields: fields,
      files: files,
      requireAuth: true,
    );

    return response;
  }
}
