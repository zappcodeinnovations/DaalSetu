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
import 'package:agro_broker/modules/settings/view/settings_page.dart';
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
      () {
        if (navController.isLoading.value) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF1A1206),
                        const Color(0xFF0D1117),
                        const Color(0xFF0D1117),
                      ]
                    : [
                        const Color(0xFFFFF8E1),
                        const Color(0xFFFFFCF5),
                        Colors.white,
                      ],
              ),
            ),
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
        );
      },
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
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
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
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 10.5 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
              child: Text(item.label),
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
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