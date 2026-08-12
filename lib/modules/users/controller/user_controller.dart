import '../model/user_model.dart';
import '../../../services/users_services.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  var isLoading = false.obs;
  var users = <UserModel>[].obs;

  @override
  void onInit() {
    fetchUsers();
    super.onInit();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final data = await UserService.getUsers();
      users.assignAll(data);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
