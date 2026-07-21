import 'package:get/get.dart';

class BottomNavController extends GetxController {
  var selectedIndex = 0.obs;

  void changeIndex(int index) {
    print("Changing to index: $index");

    selectedIndex.value = index;
  }
}
