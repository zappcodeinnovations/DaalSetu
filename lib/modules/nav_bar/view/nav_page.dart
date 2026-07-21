import 'package:agro_broker/modules/branches/view/branch_page.dart';
import 'package:agro_broker/modules/category/view/category_page.dart';
import 'package:agro_broker/modules/contracts/view/contract_view.dart';
import 'package:agro_broker/modules/dashboard/view/dashboard_page.dart';
import 'package:agro_broker/modules/kyc_users/view/kyc_user_view.dart';
import 'package:agro_broker/modules/nav_bar/controller/nav_controller.dart';
import 'package:agro_broker/modules/products/view/product_view.dart';
import 'package:agro_broker/modules/settings/view/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavigationScreen extends StatelessWidget {
  MainNavigationScreen({super.key});

  final BottomNavController navController =
      Get.put(BottomNavController());

  final List<Widget> pages = [
    AdminDashboardScreen(),
    // CategoryScreen(),
    ContractsScreen(),
    KycUsersScreen(),
    ProductScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: navController.selectedIndex.value,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: navController.selectedIndex.value,
            onTap: navController.changeIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.cardColor,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor:
                theme.textTheme.bodySmall?.color,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                label: "Contracts",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.verified_user_outlined),
                label: "Kyc Users",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                label: "Products",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: "Settings",
              ),
            ],
          ),
        ),
      ),
    );
  }
}