import 'package:get/get.dart';
import '../controller/admin_dc_list_controller.dart';
import '../controller/admin_create_dc_controller.dart';
import '../controller/admin_dc_details_controller.dart';

class AdminDCBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDCListController>(() => AdminDCListController());
    Get.lazyPut<AdminCreateDCController>(() => AdminCreateDCController());
    Get.lazyPut<AdminDCDetailsController>(() => AdminDCDetailsController());
  }
}
