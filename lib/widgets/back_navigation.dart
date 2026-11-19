import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/nav_bar/controller/nav_controller.dart';

/// What a screen's top-left back arrow does.
///
/// On a pushed screen it goes back. A screen that is a tab of the bottom bar (My Products,
/// Contracts, Offers ...) has nothing to pop, so the arrow used to do nothing at all; it now
/// returns to the first tab (the dashboard).
Future<void> goBackOrHome(BuildContext context) async {
  final popped = await Navigator.of(context).maybePop();
  if (popped) return;
  if (Get.isRegistered<BottomNavController>()) {
    final nav = Get.find<BottomNavController>();
    if (nav.selectedIndex.value != 0) nav.changeIndex(0);
  }
}
