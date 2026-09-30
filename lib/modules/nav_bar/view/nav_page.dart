import 'dart:ui';
import 'package:iconly/iconly.dart';
import 'package:agro_broker/modules/seller/dashboard/view/seller_dashboard_view.dart';
import 'package:agro_broker/modules/seller/company/view/seller_company_view.dart';
import 'package:agro_broker/modules/seller/categories/view/seller_category_view.dart';
import 'package:agro_broker/modules/contracts/view/contract_view.dart';
import 'package:agro_broker/modules/dashboard/view/dashboard_page.dart';
import 'package:agro_broker/modules/kyc_users/view/kyc_user_view.dart';
import 'package:agro_broker/modules/nav_bar/controller/nav_controller.dart';
import 'package:agro_broker/modules/products/view/product_view.dart';
import 'package:agro_broker/modules/profile/view/profile_page.dart';
import 'package:agro_broker/modules/settings/view/settings_page.dart';
import 'package:agro_broker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainNavigationScreen extends StatelessWidget {
  MainNavigationScreen({super.key});

  final BottomNavController navController = Get.put(BottomNavController());

  List<Widget> _getPages(String role) {
    if (role == 'seller') {
      return const [
        SellerDashboardView(),
        SellerCompanyView(),
        SellerCategoryView(),
      ] + [SettingsScreen()];
    }
    return [
      AdminDashboardScreen(),
      ContractsScreen(),
      KycUsersScreen(),
      ProductScreen(),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          child: IndexedStack(
            index: navController.selectedIndex.value,
            children: _getPages(navController.userRole.value),
          ),
        ),
        bottomNavigationBar: _GlassNavBar(
          currentIndex: navController.selectedIndex.value,
          role: navController.userRole.value,
          onTap: navController.changeIndex,
        ),
      ),
    );
  }
}

/// ─── FLOATING GLASS BOTTOM NAV BAR ────────────────────────────────────────
class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final String role;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.currentIndex,
    required this.role,
    required this.onTap,
  });

  List<_NavItem> get _items {
    if (role == 'seller') {
      return const [
        _NavItem(icon: IconlyLight.category, activeIcon: IconlyBold.category, label: 'Dashboard'),
        _NavItem(icon: IconlyLight.home, activeIcon: IconlyBold.home, label: 'Company'),
        _NavItem(icon: IconlyLight.document, activeIcon: IconlyBold.document, label: 'Category'),
        _NavItem(icon: IconlyLight.setting, activeIcon: IconlyBold.setting, label: 'Settings'),
      ];
    }
    return const [
      _NavItem(icon: IconlyLight.category, activeIcon: IconlyBold.category, label: 'Dashboard'),
      _NavItem(icon: IconlyLight.document, activeIcon: IconlyBold.document, label: 'Contracts'),
      _NavItem(icon: IconlyLight.user_1, activeIcon: IconlyBold.user_3, label: 'KYC'),
      _NavItem(icon: IconlyLight.bag, activeIcon: IconlyBold.bag, label: 'Products'),
      _NavItem(icon: IconlyLight.setting, activeIcon: IconlyBold.setting, label: 'Settings'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _items.length,
                (index) => _buildNavItem(context, index, _items),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, List<_NavItem> items) {
    final theme = Theme.of(context);
    final isSelected = currentIndex == index;
    final item = items[index];

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGold
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected
                  ? Colors.white
                  : theme.iconTheme.color,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 10.5 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodySmall?.color,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}