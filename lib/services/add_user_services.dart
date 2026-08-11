import 'dart:io';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/comman/api_url.dart';

class AddUserServices {

  static Future<Map<String, dynamic>> addUser({
    required String mobile,
    required String email,
    required String firstName,
    String? lastName,
    required String role,
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
    };

    if (lastName != null) fields["last_name"] = lastName;
    if (panNumber != null) fields["pan_number"] = panNumber;
    if (gstNumber != null) fields["gst_number"] = gstNumber;
    if (gender != null) fields["gender"] = gender;
    if (dob != null) fields["dob"] = dob;

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
