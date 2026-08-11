import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/modules/users/model/user_model.dart';
import '../network/api_client.dart';

class UserService {

  static Future<List<UserModel>> getUsers() async {

    final response = await ApiClient.get(
      endpoint: ApiUrls.users, // "/users/"
      requireAuth: true,
    );

    if (response == null || response is! List) {
      throw Exception("Invalid users response");
    }

    return response
        .map<UserModel>((e) => UserModel.fromJson(e))
        .toList();
  }
}
