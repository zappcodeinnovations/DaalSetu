import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:daalsetu/theme/app_theme.dart';
import '../controller/drawer_controller.dart' as admin;

// Buyer views & dependencies
import 'package:daalsetu/modules/buyer/branch/view/buyer_branch_view.dart';
import 'package:daalsetu/modules/buyer/consignment/view/buyer_consignment_view.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/view/buyer_delivery_challan_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_my_interests_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offers_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_request_management_view.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_today_offers_view.dart';
import 'package:daalsetu/modules/category/view/category_page.dart';
import 'package:daalsetu/modules/contracts/view/contract_view.dart';
import 'package:daalsetu/modules/nav_bar/controller/nav_controller.dart';
import 'package:daalsetu/modules/seller/company/view/seller_company_view.dart';
import 'package:daalsetu/modules/settings/view/settings_page.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';
import 'package:daalsetu/utils/app_preferences.dart';

// Seller & Transporter views
import 'package:daalsetu/modules/seller/products/view/seller_product_view.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/view/add_product_view.dart';
import 'package:daalsetu/modules/seller/rfq/view/seller_rfq_list_view.dart';
import 'package:daalsetu/modules/seller/buyer_offers/view/seller_buyer_offers_view.dart';
import 'package:daalsetu/modules/seller/masters/view/seller_master_management_view.dart';
import 'package:daalsetu/modules/seller/consignments/view/seller_consignments_view.dart';
import 'package:daalsetu/modules/seller/contracts/view/seller_contracts_view.dart';
import 'package:daalsetu/modules/seller/branches/view/seller_branches_view.dart';
import 'package:daalsetu/modules/seller/challans/view/seller_delivery_challan_view.dart';
import 'package:daalsetu/modules/transporter/bidding/view/transporter_bidding_view.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, this.activeKey});
  final String? activeKey;

  static double widthFor(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700 ? 340 : 306;

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(admin.DrawerController());
    if (controller.isStale) {
      // Another user signed in since this menu was loaded: reload after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.refreshMenu());
    }
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      width: widthFor(context),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/thumb_logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DaalSetu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Obx(() {
                          final role = controller.userRole.value.toLowerCase();
                          final isAdmin = const ['super_admin', 'admin', 'sub_admin']
                              .contains(role);
                          final subtitle = controller.isLoading.value || controller.isStale
                              ? ''
                              : isAdmin
                              ? 'ADMIN PANEL'
                              : (role == 'seller'
                                  ? 'SELLER PANEL'
                                  : (role == 'transporter'
                                      ? 'TRANSPORTER PANEL'
                                      : 'BUYER PANEL'));
                          return Text(
                            subtitle,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close menu',
                    onPressed: () {
                      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                        Scaffold.of(context).closeDrawer();
                      } else {
                        Navigator.maybeOf(context)?.maybePop();
                      }
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Nav List ─────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value || controller.isStale) {
                  return const Center(child: CircularProgressIndicator());
                }

                final role = controller.userRole.value.toLowerCase();
                final isAdmin = const ['super_admin', 'admin', 'sub_admin']
                    .contains(role);

                // Role-based Drawer Routing
                if (isAdmin) {
                  return _buildAdminMenu(context, controller);
                } else if (role == 'seller' || role == 'both_sellerandbuyer') {
                  return _buildSellerMenu(context, controller);
                } else if (role == 'transporter') {
                  return _buildTransporterMenu(context, controller);
                } else {
                  return _buildBuyerMenu(context, controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADMIN MENU ─────────────────────────────────────────────────────────────
  Widget _buildAdminMenu(
      BuildContext context, admin.DrawerController controller) {
    if (controller.hasError.value) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load menu.\n${controller.errorMessage.value}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (controller.menuSections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No menu items available'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _customMenuItem(
          context: context,
          key: 'dashboard',
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          onTap: _goToDashboard,
        ),
        for (var section in controller.menuSections)
          _buildSection(context, section, controller),
        _sectionLabel(context, 'FILES'),
        _downloadsMenuItem(context),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    DrawerMenuSection section,
    admin.DrawerController controller,
  ) {
    final visibleItems = section.items
        .where((item) => item.isVisibleFor(controller.userRole.value))
        .toList();

    if (visibleItems.isEmpty) return const SizedBox.shrink();

    final isExpanded = section.sectionTitle == 'MASTERS'
        ? controller.mastersExpanded.value
        : section.sectionTitle == 'OFFER'
            ? controller.offersExpanded.value
            : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          onTap: () {
            if (section.sectionTitle == 'MASTERS') {
              controller.toggleMasters();
            } else if (section.sectionTitle == 'OFFER') {
              controller.toggleOffers();
            }
          },
          title: Text(
            section.sectionTitle,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: visibleItems
                .map((item) => _menuItem(context, item, controller))
                .toList(),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _menuItem(BuildContext context, DrawerMenuItem item,
      admin.DrawerController controller) {
    final active = activeKey == item.key;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: ListTile(
        selected: active,
        selectedTileColor: AppTheme.primaryGold.withValues(alpha: .13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          item.icon,
          size: 21,
          color: active ? AppTheme.primaryGold : theme.iconTheme.color,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            color: active
                ? AppTheme.primaryGold
                : theme.textTheme.bodyMedium?.color,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        trailing: active
            ? Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        onTap: () {
          _closeDrawer(context);
          controller.handleNavigation(item.route);
        },
      ),
    );
  }

  // ── BUYER MENU ─────────────────────────────────────────────────────────────
  Widget _buildBuyerMenu(
      BuildContext context, admin.DrawerController controller) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _customMenuItem(
          context: context,
          key: 'dashboard',
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          onTap: _goToDashboard,
        ),
        _customMenuItem(
          context: context,
          key: 'categories',
          title: 'My Categories',
          icon: Icons.category_outlined,
          onTap: () => Get.to(() => const CategoryPageView()),
        ),
        _customMenuItem(
          context: context,
          key: 'registered_company',
          title: 'Registered Company',
          icon: Icons.apartment_rounded,
          onTap: () => Get.to(() => const SellerCompanyView()),
        ),
        const SizedBox(height: 6),
        Obx(() {
          final isExpanded = controller.offersExpanded.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: true,
                onTap: controller.toggleOffers,
                title: Text(
                  'OFFER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                trailing: Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    _customMenuItem(
                      context: context,
                      key: 'offers',
                      title: 'Browse Offers',
                      icon: Icons.local_offer_outlined,
                      isSubItem: true,
                      onTap: () =>
                          Get.to(() => const BuyerOffersView(initialIndex: 0)),
                    ),
                    _customMenuItem(
                      context: context,
                      key: 'my_interests',
                      title: 'My Interests',
                      icon: Icons.favorite_border_rounded,
                      isSubItem: true,
                      onTap: () => Get.to(() => const BuyerMyInterestsView()),
                    ),
                    _customMenuItem(
                      context: context,
                      key: 'buyer_requirements',
                      title: 'Buyer Requirements',
                      icon: Icons.assignment_outlined,
                      isSubItem: true,
                      onTap: () => Get.to(() => const BuyerRequestManagementView(
                            mode: BuyerRequestMode.requirements,
                            wrapInScaffold: true,
                          )),
                    ),
                    _customMenuItem(
                      context: context,
                      key: 'today_offers',
                      title: "Today's Offers",
                      icon: Icons.today_outlined,
                      isSubItem: true,
                      onTap: () => Get.to(() => const BuyerTodayOffersView()),
                    ),
                  ],
                ),
                secondChild: const SizedBox(width: double.infinity),
              ),
            ],
          );
        }),
        const SizedBox(height: 6),
        _customMenuItem(
          context: context,
          key: 'branches',
          title: 'Branches',
          icon: Icons.store_mall_directory_outlined,
          onTap: () => Get.to(() => const BuyerBranchView()),
        ),
        _customMenuItem(
          context: context,
          key: 'deals',
          title: 'Deals',
          icon: Icons.handshake_outlined,
          onTap: () => Get.to(() => const ContractsScreen()),
        ),
        _customMenuItem(
          context: context,
          key: 'delivery_challans',
          title: 'Delivery Challans',
          icon: Icons.local_shipping_outlined,
          onTap: () => Get.to(() => const BuyerDeliveryChallanView()),
        ),
        _customMenuItem(
          context: context,
          key: 'consignments',
          title: 'Consignments',
          icon: Icons.inventory_2_outlined,
          onTap: () => Get.to(() => const BuyerConsignmentView()),
        ),
        _sectionLabel(context, 'FILES'),
        _downloadsMenuItem(context),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        _customMenuItem(
          context: context,
          key: 'settings',
          title: 'Settings',
          icon: Icons.settings_outlined,
          onTap: () => Get.to(() => SettingsScreen()),
        ),
        _customMenuItem(
          context: context,
          key: 'logout',
          title: 'Log Out',
          icon: Icons.logout_rounded,
          onTap: _logout,
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await AppPreferences.logout();
    if (Get.isRegistered<RealtimeNotificationService>()) {
      RealtimeNotificationService.to.clearOnLogout();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  // ── SELLER MENU ────────────────────────────────────────────────────────────
  Widget _buildSellerMenu(
      BuildContext context, admin.DrawerController controller) {
    // The one place for seller tools: replaces the old Seller Workspace page and
    // the dashboard shortcut cards (same groups and screens).
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _customMenuItem(
          context: context,
          key: 'dashboard',
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          onTap: _goToDashboard,
        ),
        _sectionLabel(context, 'OFFERS'),
        _customMenuItem(
          context: context,
          key: 'create_offer',
          title: 'Create Offer',
          icon: Icons.add_box_outlined,
          onTap: () {
            if (!Get.isRegistered<SellerProductController>()) {
              Get.put(SellerProductController());
            }
            Get.to(() => const AddProductView());
          },
        ),
        _customMenuItem(
          context: context,
          key: 'products',
          title: 'My Offers',
          icon: Icons.inventory_2_outlined,
          onTap: () => Get.to(() => const SellerProductView()),
        ),
        _customMenuItem(
          context: context,
          key: 'buyer_requirements',
          title: 'Buyer Requirements',
          icon: Icons.request_quote_outlined,
          onTap: () => Get.to(() => const SellerRfqListView()),
        ),
        _customMenuItem(
          context: context,
          key: 'buyer_offers',
          title: 'Buyer Offers',
          icon: Icons.local_offer_outlined,
          onTap: () => Get.to(() => const SellerBuyerOffersView()),
        ),
        _sectionLabel(context, 'MASTERS & BUSINESS'),
        _customMenuItem(
          context: context,
          key: 'categories',
          title: 'Category Master',
          icon: Icons.category_outlined,
          onTap: () => Get.toNamed(AppRoutes.sellerCategory),
        ),
        _customMenuItem(
          context: context,
          key: 'masters',
          title: 'Brand & Tag Master',
          icon: Icons.bookmarks_outlined,
          onTap: () => Get.to(() => const SellerMasterManagementView()),
        ),
        _customMenuItem(
          context: context,
          key: 'company',
          title: 'Companies',
          icon: Icons.business_outlined,
          onTap: () => Get.to(() => const SellerCompanyView()),
        ),
        _customMenuItem(
          context: context,
          key: 'branches',
          title: 'My Branches',
          icon: Icons.store_mall_directory_outlined,
          onTap: () => Get.to(() => const SellerBranchesView()),
        ),
        _sectionLabel(context, 'DEALS & DISPATCH'),
        _customMenuItem(
          context: context,
          key: 'contracts',
          title: 'Contracts',
          icon: Icons.description_outlined,
          onTap: () => Get.to(() => const SellerContractsView()),
        ),
        _customMenuItem(
          context: context,
          key: 'consignments',
          title: 'Consignments',
          icon: Icons.inventory_outlined,
          onTap: () => Get.to(() => const SellerConsignmentsView()),
        ),
        _customMenuItem(
          context: context,
          key: 'delivery_challans',
          title: 'Delivery Challans',
          icon: Icons.local_shipping_outlined,
          onTap: () => Get.to(() => const SellerDeliveryChallanView()),
        ),
        _sectionLabel(context, 'FILES'),
        _downloadsMenuItem(context),
        _sectionLabel(context, 'SETTINGS'),
        _customMenuItem(
          context: context,
          key: 'settings',
          title: 'Settings',
          icon: Icons.settings_outlined,
          onTap: () => Get.to(() => SettingsScreen()),
        ),
        _customMenuItem(
          context: context,
          key: 'logout',
          title: 'Log Out',
          icon: Icons.logout_rounded,
          onTap: _logout,
        ),
      ],
    );
  }

  // ── TRANSPORTER MENU ───────────────────────────────────────────────────────
  Widget _buildTransporterMenu(
      BuildContext context, admin.DrawerController controller) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        _customMenuItem(
          context: context,
          key: 'dashboard',
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          onTap: _goToDashboard,
        ),
        // Grouped like the web transporter sidebar; these replace the dashboard shortcut cards.
        _sectionLabel(context, 'SHIPMENT'),
        _customMenuItem(
          context: context,
          key: 'shipment_offers',
          title: 'Shipment Offers',
          icon: Icons.local_shipping_outlined,
          onTap: () => Get.to(() => const TransporterBiddingView()),
        ),
        _customMenuItem(
          context: context,
          key: 'my_deals',
          title: 'My Deals',
          icon: Icons.assignment_turned_in_outlined,
          onTap: () => Get.to(() => const TransporterBiddingView(initialTab: 1)),
        ),
        _sectionLabel(context, 'MASTERS'),
        _customMenuItem(
          context: context,
          key: 'drivers',
          title: 'Drivers',
          icon: Icons.badge_outlined,
          onTap: () => Get.toNamed(AppRoutes.transporterDrivers),
        ),
        _customMenuItem(
          context: context,
          key: 'vehicles',
          title: 'Vehicles',
          icon: Icons.directions_bus_outlined,
          onTap: () => Get.toNamed(AppRoutes.transporterVehicles),
        ),
        _sectionLabel(context, 'ACCOUNT'),
        _customMenuItem(
          context: context,
          key: 'company',
          title: 'Company',
          icon: Icons.business_outlined,
          onTap: () => Get.toNamed(AppRoutes.transporterCompany),
        ),
        _customMenuItem(
          context: context,
          key: 'branches',
          title: 'My Branches',
          icon: Icons.store_mall_directory_outlined,
          onTap: () => Get.to(() => const SellerBranchesView()),
        ),
        _sectionLabel(context, 'FILES'),
        _downloadsMenuItem(context),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        _customMenuItem(
          context: context,
          key: 'settings',
          title: 'Settings',
          icon: Icons.settings_outlined,
          onTap: () => Get.to(() => SettingsScreen()),
        ),
        _customMenuItem(
          context: context,
          key: 'logout',
          title: 'Log Out',
          icon: Icons.logout_rounded,
          onTap: _logout,
        ),
      ],
    );
  }

  /// Back to the role's dashboard tab from anywhere in the app.
  static void _goToDashboard() {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().changeIndex(0);
      Get.until((route) => route.settings.name == AppRoutes.mainNav || route.isFirst);
    } else {
      Get.offAllNamed(AppRoutes.mainNav);
    }
  }

  /// Closes a page's own Scaffold drawer, or pops the app-wide drawer route
  /// (AppShell.openDrawer).
  static void _closeDrawer(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    } else {
      Navigator.maybeOf(context)?.maybePop();
    }
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6, top: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _downloadsMenuItem(BuildContext context) => _customMenuItem(
        context: context,
        key: 'downloads',
        title: 'Downloads',
        icon: Icons.folder_open_outlined,
        onTap: () => Get.toNamed(AppRoutes.downloads),
      );

  // ── CUSTOM MENU ITEM HELPER ────────────────────────────────────────────────
  Widget _customMenuItem({
    required BuildContext context,
    required String key,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isSubItem = false,
  }) {
    final active = activeKey == key ||
        (activeKey == 'deals' && (key == 'deals' || key == 'contracts')) ||
        (activeKey == 'buyer_offers' &&
            (key == 'deals' || key == 'offers' || key == 'today_offers'));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 3, left: isSubItem ? 12 : 0),
      child: ListTile(
        selected: active,
        selectedTileColor: AppTheme.primaryGold.withValues(alpha: .13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          size: isSubItem ? 19 : 21,
          color: active ? AppTheme.primaryGold : theme.iconTheme.color,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isSubItem ? 13.5 : 14,
            color: active
                ? AppTheme.primaryGold
                : theme.textTheme.bodyMedium?.color,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        trailing: active
            ? Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        onTap: () {
          _closeDrawer(context);
          onTap();
        },
      ),
    );
  }
}
