import 'package:agro_broker/modules/Auth/login/controller/login_controller.dart';
import 'package:agro_broker/modules/Auth/register/controller/register_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<RegisterController>(() => RegisterController());
  }
}
