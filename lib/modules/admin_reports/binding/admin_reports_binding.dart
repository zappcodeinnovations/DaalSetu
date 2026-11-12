import 'package:get/get.dart';
import '../controller/admin_reports_controller.dart';

class AdminReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminReportsController>(() => AdminReportsController());
  }
}
