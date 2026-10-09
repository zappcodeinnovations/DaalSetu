import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../seller/dashboard/view/seller_dashboard_view.dart';
import '../../seller/products/view/seller_product_view.dart';
import '../../seller/contracts/view/seller_contracts_view.dart';
import '../../seller/workspace/view/seller_workspace_view.dart';
import '../../contracts/view/contract_view.dart';
import '../../dashboard/view/dashboard_page.dart';
import '../../kyc_users/view/kyc_user_view.dart';
import '../controller/nav_controller.dart';
import '../../products/view/product_view.dart';
import '../../transporter/dashboard/view/transporter_dashboard_view.dart';
import '../../transporter/drivers/view/transporter_drivers_view.dart';
import '../../transporter/vehicles/view/transporter_vehicles_view.dart';
import '../../transporter/bidding/view/transporter_bidding_view.dart';
import '../../buyer/dashboard/view/buyer_dashboard_view.dart';
import '../../buyer/offers/view/buyer_offers_view.dart';
import '../../buyer/delivery_challan/view/buyer_delivery_challan_view.dart';
import '../../buyer/branch/view/buyer_branch_view.dart';
import '../../settings/view/settings_page.dart';

class MainNavigationScreen extends StatelessWidget {
  MainNavigationScreen({super.key});

  final BottomNavController navController = Get.put(BottomNavController());

  List<Widget> _getPages(String role) {
    // "both_sellerandbuyer" users get the seller app instead of falling through to admin tabs.
    if (role == 'seller' || role == 'both_sellerandbuyer') {
      return [
            SellerDashboardView(),
            const SellerProductView(),
            const SellerWorkspaceView(),
            const SellerContractsView(),
          ] +
          [SettingsScreen()];
    }
    if (role == 'transporter') {
      return [
            TransporterDashboardView(),
            const TransporterBiddingView(),
            TransporterDriversView(),
            const TransporterVehiclesView(),
          ] +
          [SettingsScreen()];
    }
    if (role == 'buyer' ||
        role == 'both_sellerandbuyer' ||
        role == 'buyer_seller' ||
        role == 'both') {
      return [
            BuyerDashboardView(),
            const BuyerOffersView(),
            const BuyerDeliveryChallanView(),
            BuyerBranchView(),
          ] +
          [SettingsScreen()];
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
    return Obx(() {
      if (navController.isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        resizeToAvoidBottomInset: navController.userRole.value == 'admin' ? false : true,
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
      );
    });
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
    if (role == 'seller' || role == 'both_sellerandbuyer') {
      return const [
        _NavItem(
          icon: IconlyLight.category,
          activeIcon: IconlyBold.category,
          label: 'Dashboard',
        ),
        _NavItem(
          icon: IconlyLight.bag,
          activeIcon: IconlyBold.bag,
          label: 'Offers',
        ),
        _NavItem(
          icon: IconlyLight.category,
          activeIcon: IconlyBold.category,
          label: 'Menu',
        ),
        _NavItem(
          icon: IconlyLight.paper,
          activeIcon: IconlyBold.paper,
          label: 'Deals',
        ),
        _NavItem(
          icon: IconlyLight.setting,
          activeIcon: IconlyBold.setting,
          label: 'Settings',
        ),
      ];
    }
    if (role == 'transporter') {
      return const [
        _NavItem(
          icon: IconlyLight.category,
          activeIcon: IconlyBold.category,
          label: 'Dashboard',
        ),
        _NavItem(
          icon: IconlyLight.ticket_star,
          activeIcon: IconlyBold.ticket_star,
          label: 'Shipments',
        ),
        _NavItem(
          icon: IconlyLight.user_1,
          activeIcon: IconlyBold.user_3,
          label: 'Drivers',
        ),
        _NavItem(
          icon: IconlyLight.discovery,
          activeIcon: IconlyBold.discovery,
          label: 'Vehicles',
        ),
        _NavItem(
          icon: IconlyLight.setting,
          activeIcon: IconlyBold.setting,
          label: 'Settings',
        ),
      ];
    }
    if (role == 'buyer' ||
        role == 'both_sellerandbuyer' ||
        role == 'buyer_seller' ||
        role == 'both') {
      return const [
        _NavItem(
          icon: IconlyLight.category,
          activeIcon: IconlyBold.category,
          label: 'Dashboard',
        ),
        _NavItem(
          icon: IconlyLight.ticket_star,
          activeIcon: IconlyBold.ticket_star,
          label: 'Offers',
        ),
        _NavItem(
          icon: IconlyLight.document,
          activeIcon: IconlyBold.document,
          label: 'Challan',
        ),
        _NavItem(
          icon: IconlyLight.location,
          activeIcon: IconlyBold.location,
          label: 'Branch',
        ),
        _NavItem(
          icon: IconlyLight.setting,
          activeIcon: IconlyBold.setting,
          label: 'Settings',
        ),
      ];
    }
    return const [
      _NavItem(
        icon: IconlyLight.category,
        activeIcon: IconlyBold.category,
        label: 'Dashboard',
      ),
      _NavItem(
        icon: IconlyLight.document,
        activeIcon: IconlyBold.document,
        label: 'Contracts',
      ),
      _NavItem(
        icon: IconlyLight.user_1,
        activeIcon: IconlyBold.user_3,
        label: 'KYC',
      ),
      _NavItem(
        icon: IconlyLight.bag,
        activeIcon: IconlyBold.bag,
        label: 'Products',
      ),
      _NavItem(
        icon: IconlyLight.setting,
        activeIcon: IconlyBold.setting,
        label: 'Settings',
      ),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
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
          color: isSelected ? AppTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected ? Colors.white : theme.iconTheme.color,
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
