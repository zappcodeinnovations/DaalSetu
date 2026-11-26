import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:daalsetu/modules/admin_catalog/model/drawer_menu_model.dart';
import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
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
import 'package:daalsetu/services/panel_service.dart';
import 'package:daalsetu/utils/app_snackbar.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(context, controller),

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

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, admin.DrawerController controller) {
    final topInset = MediaQuery.of(context).padding.top;

    return Obx(() {
      final role = controller.userRole.value.toLowerCase();
      final isAdmin =
          const ['super_admin', 'admin', 'sub_admin'].contains(role);
      final subtitle = controller.isLoading.value || controller.isStale
          ? ''
          : isAdmin
              ? 'ADMIN PANEL'
              : (role == 'seller'
                  ? 'SELLER PANEL'
                  : (role == 'transporter'
                      ? 'TRANSPORTER PANEL'
                      : 'BUYER PANEL'));

      String title = 'DaalSetu';
      if (role == 'buyer' ||
          (!isAdmin &&
              role != 'seller' &&
              role != 'transporter' &&
              role != 'both_sellerandbuyer')) {
        if (Get.isRegistered<ProfileController>()) {
          final profile = Get.find<ProfileController>().profile.value;
          if (profile != null) {
            final fullName = '${profile.firstName} ${profile.lastName}'.trim();
            if (fullName.isNotEmpty) {
              title = fullName;
            } else if (profile.username.isNotEmpty) {
              title = profile.username;
            }
          }
        }
      }

      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE65100), // Deep rich saffron
              Color(0xFFF57C00), // Vibrant amber orange
              Color(0xFFFFA000), // Warm gold highlight
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(18, topInset + 14, 14, 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/thumb_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: 'Close menu',
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => _closeDrawer(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    });
  }

  ({Color color, Color bg}) _adminIconPalette(String key) {
    switch (key.toLowerCase()) {
      case 'dashboard':
        return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
      case 'notifications':
        return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED));
      case 'complaints':
        return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2));
      case 'registered_company':
        return (color: const Color(0xFF4F46E5), bg: const Color(0xFFEEF2FF));
      case 'users':
        return (color: const Color(0xFF0284C7), bg: const Color(0xFFE0F2FE));
      case 'kyc':
        return (color: const Color(0xFF059669), bg: const Color(0xFFECFDF5));
      case 'category_requests':
        return (color: const Color(0xFF7C3AED), bg: const Color(0xFFF5F3FF));
      case 'categories':
        return (color: const Color(0xFF0891B2), bg: const Color(0xFFECFEFF));
      case 'sub_categories':
        return (color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF));
      case 'brands':
        return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
      case 'tags':
        return (color: const Color(0xFF9333EA), bg: const Color(0xFFFAF5FF));
      case 'drivers':
        return (color: const Color(0xFF0D9488), bg: const Color(0xFFF0FDFA));
      case 'vehicles':
        return (color: const Color(0xFF4338CA), bg: const Color(0xFFEEF2FF));
      case 'branch_requests':
      case 'branches':
      case 'branch_settings':
        return (color: const Color(0xFF0F766E), bg: const Color(0xFFCCFBF1));
      case 'offers':
      case 'products':
        return (color: const Color(0xFFE65100), bg: const Color(0xFFFFF7ED));
      case 'delivery_challans':
      case 'challans':
        return (color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF));
      case 'brokerage_bills':
      case 'bills':
        return (color: const Color(0xFF059669), bg: const Color(0xFFECFDF5));
      case 'branch_reports':
      case 'reports':
        return (color: const Color(0xFF0284C7), bg: const Color(0xFFE0F2FE));
      case 'roles':
      case 'permissions':
      case 'sub_admin_permissions':
        return (color: const Color(0xFF7C3AED), bg: const Color(0xFFF5F3FF));
      case 'downloads':
        return (color: const Color(0xFF475569), bg: const Color(0xFFF1F5F9));
      case 'settings':
        return (color: const Color(0xFF64748B), bg: const Color(0xFFF1F5F9));
      case 'logout':
        return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2));
      default:
        return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED));
    }
  }

  IconData _sectionIcon(String title) {
    switch (title.toUpperCase()) {
      case 'GENERAL':
        return Icons.dashboard_customize_outlined;
      case 'MASTERS':
        return Icons.folder_shared_outlined;
      case 'BRANCHES':
        return Icons.store_mall_directory_outlined;
      case 'OFFER':
        return Icons.local_offer_outlined;
      case 'DELIVERY CHALLAN':
        return Icons.local_shipping_outlined;
      case 'BILLING & REPORTS':
        return Icons.receipt_long_outlined;
      case 'GOVERNANCE':
        return Icons.security_outlined;
      default:
        return Icons.category_outlined;
    }
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        // ── Overview ───────────────────────────────────────────
        _buyerSectionHeader(context, 'OVERVIEW', Icons.home_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'dashboard',
              title: 'Dashboard',
              icon: Icons.dashboard_outlined,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              onTap: _goToDashboard,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Dynamic Admin Sections ─────────────────────────────
        for (var section in controller.menuSections)
          _buildSection(context, section, controller),

        // ── Files & System ─────────────────────────────────────
        _buyerSectionHeader(context, 'FILES & SYSTEM', Icons.settings_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'downloads',
              title: 'Downloads',
              icon: Icons.download_rounded,
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF475569),
              iconBgColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              onTap: () => Get.toNamed(AppRoutes.downloads),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'settings',
              title: 'Settings',
              icon: Icons.settings_outlined,
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF6366F1),
              iconBgColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFEEF2FF),
              onTap: () => Get.to(() => SettingsScreen()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'logout',
              title: 'Log Out',
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBgColor: const Color(0xFFFEF2F2),
              onTap: _logout,
            ),
          ],
        ),
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

    final isMasters = section.sectionTitle == 'MASTERS';
    final isOffers = section.sectionTitle == 'OFFER';
    final isCollapsible = isMasters || isOffers;
    final isExpanded = isMasters
        ? controller.mastersExpanded.value
        : isOffers
            ? controller.offersExpanded.value
            : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCollapsible)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (isMasters) controller.toggleMasters();
              if (isOffers) controller.toggleOffers();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _sectionIcon(section.sectionTitle),
                    size: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.sectionTitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
            ),
          )
        else
          _buyerSectionHeader(
            context,
            section.sectionTitle,
            _sectionIcon(section.sectionTitle),
          ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: _buyerCardGroup(
            context,
            children: [
              for (int i = 0; i < visibleItems.length; i++) ...[
                if (i > 0) _buyerDivider(context),
                _adminMenuItemWidget(context, visibleItems[i], controller),
              ],
            ],
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _adminMenuItemWidget(
    BuildContext context,
    DrawerMenuItem item,
    admin.DrawerController controller,
  ) {
    final palette = _adminIconPalette(item.key);
    return _buyerMenuItem(
      context: context,
      key: item.key,
      title: item.title,
      icon: item.icon,
      iconColor: palette.color,
      iconBgColor: palette.bg,
      onTap: () => controller.handleNavigation(item.route),
    );
  }

  // ── BUYER MENU ─────────────────────────────────────────────────────────────
  Widget _buildBuyerMenu(
      BuildContext context, admin.DrawerController controller) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        // ── 1. Overview & Business ──────────────────────────────
        _buyerSectionHeader(
            context, 'OVERVIEW & BUSINESS', Icons.business_center_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'dashboard',
              title: 'Dashboard',
              icon: Icons.dashboard_outlined,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              onTap: _goToDashboard,
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'categories',
              title: 'My Categories',
              icon: Icons.category_outlined,
              iconColor: const Color(0xFF0891B2),
              iconBgColor: const Color(0xFFECFEFF),
              onTap: () => Get.to(() => const CategoryPageView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'registered_company',
              title: 'Registered Company',
              icon: Icons.apartment_rounded,
              iconColor: const Color(0xFF4F46E5),
              iconBgColor: const Color(0xFFEEF2FF),
              onTap: () => Get.to(() => const SellerCompanyView()),
            ),
            if (controller.isCombinedAccount.value) ...[
              _buyerDivider(context),
              _buyerMenuItem(
                context: context,
                key: 'switch_panel',
                title: 'Switch to Seller panel',
                icon: Icons.swap_horiz_rounded,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFF7ED),
                onTap: () => switchPanelFromMenu('seller'),
              ),
            ],
          ],
        ),

        // ── 2. Marketplace & Offers ─────────────────────────────
        _buyerSectionHeader(
            context, 'MARKETPLACE & OFFERS', Icons.storefront_outlined),
        Obx(() {
          final isExpanded = controller.offersExpanded.value;
          return _buyerCardGroup(
            context,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.toggleOffers,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.layers_rounded,
                            size: 19,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Offers & Requirements',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    _buyerDivider(context),
                    _buyerMenuItem(
                      context: context,
                      key: 'offers',
                      title: 'Browse Offers',
                      icon: Icons.local_offer_outlined,
                      iconColor: const Color(0xFFEA580C),
                      iconBgColor: const Color(0xFFFFF7ED),
                      onTap: () =>
                          Get.to(() => const BuyerOffersView(initialIndex: 0)),
                    ),
                    _buyerDivider(context),
                    _buyerMenuItem(
                      context: context,
                      key: 'today_offers',
                      title: "Today's Offers",
                      icon: Icons.today_outlined,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFFEF3C7),
                      onTap: () => Get.to(() => const BuyerTodayOffersView()),
                    ),
                    _buyerDivider(context),
                    _buyerMenuItem(
                      context: context,
                      key: 'my_interests',
                      title: 'My Interests',
                      icon: Icons.favorite_border_rounded,
                      iconColor: const Color(0xFFE11D48),
                      iconBgColor: const Color(0xFFFFF1F2),
                      onTap: () => Get.to(() => const BuyerMyInterestsView()),
                    ),
                    _buyerDivider(context),
                    _buyerMenuItem(
                      context: context,
                      key: 'buyer_requirements',
                      title: 'Buyer Requirements',
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF4F46E5),
                      iconBgColor: const Color(0xFFEEF2FF),
                      onTap: () => Get.to(() => const BuyerRequestManagementView(
                            mode: BuyerRequestMode.requirements,
                            wrapInScaffold: true,
                          )),
                    ),
                  ],
                ),
                secondChild: const SizedBox(width: double.infinity),
              ),
            ],
          );
        }),

        // ── 3. Deals & Logistics ────────────────────────────────
        _buyerSectionHeader(
            context, 'DEALS & LOGISTICS', Icons.local_shipping_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'deals',
              title: 'Deals',
              icon: Icons.handshake_outlined,
              iconColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFECFDF5),
              onTap: () => Get.to(() => const ContractsScreen()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'delivery_challans',
              title: 'Delivery Challans',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFEFF6FF),
              onTap: () => Get.to(() => const BuyerDeliveryChallanView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'consignments',
              title: 'Consignments',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFF0FDFA),
              onTap: () => Get.to(() => const BuyerConsignmentView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'branches',
              title: 'Branches',
              icon: Icons.store_mall_directory_outlined,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFF5F3FF),
              onTap: () => Get.to(() => const BuyerBranchView()),
            ),
          ],
        ),

        // ── 4. Insights & Files ─────────────────────────────────
        _buyerSectionHeader(
            context, 'INSIGHTS & FILES', Icons.insights_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'my_analytics',
              title: 'My Analytics',
              icon: Icons.insights_outlined,
              iconColor: const Color(0xFFE11D48),
              iconBgColor: const Color(0xFFFFF1F2),
              onTap: () => Get.toNamed(AppRoutes.myAnalytics),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'downloads',
              title: 'Downloads',
              icon: Icons.folder_open_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFF0F9FF),
              onTap: () => Get.toNamed(AppRoutes.downloads),
            ),
          ],
        ),

        // ── 5. Preferences & Account ─────────────────────────────
        _buyerSectionHeader(
            context, 'PREFERENCES & ACCOUNT', Icons.tune_rounded),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'settings',
              title: 'Settings',
              icon: Icons.settings_outlined,
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF6366F1),
              iconBgColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFEEF2FF),
              onTap: () => Get.to(() => SettingsScreen()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'logout',
              title: 'Log Out',
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBgColor: const Color(0xFFFEF2F2),
              onTap: _logout,
            ),
          ],
        ),

        const SizedBox(height: 10),
        Center(
          child: Text(
            'DaalSetu • Pulse Trading Platform',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
      children: [
        // ── 1. Overview & Business ──────────────────────────────
        _buyerSectionHeader(
            context, 'OVERVIEW & BUSINESS', Icons.business_center_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'dashboard',
              title: 'Dashboard',
              icon: Icons.dashboard_outlined,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              onTap: _goToDashboard,
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'categories',
              title: 'Category Master',
              icon: Icons.category_outlined,
              iconColor: const Color(0xFF0891B2),
              iconBgColor: const Color(0xFFECFEFF),
              onTap: () => Get.toNamed(AppRoutes.sellerCategory),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'company',
              title: 'Companies',
              icon: Icons.apartment_rounded,
              iconColor: const Color(0xFF4F46E5),
              iconBgColor: const Color(0xFFEEF2FF),
              onTap: () => Get.to(() => const SellerCompanyView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'branches',
              title: 'My Branches',
              icon: Icons.store_mall_directory_outlined,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFCCFBF1),
              onTap: () => Get.to(() => const SellerBranchesView()),
            ),
            if (controller.isCombinedAccount.value) ...[
              _buyerDivider(context),
              _buyerMenuItem(
                context: context,
                key: 'switch_panel',
                title: 'Switch to Buyer panel',
                icon: Icons.swap_horiz_rounded,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFF7ED),
                onTap: () => switchPanelFromMenu('buyer'),
              ),
            ],
          ],
        ),

        // ── 2. Offers & Inventory ───────────────────────────────
        _buyerSectionHeader(
            context, 'OFFERS & INVENTORY', Icons.storefront_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'create_offer',
              title: 'Create Offer',
              icon: Icons.add_circle_outline_rounded,
              iconColor: const Color(0xFFEA580C),
              iconBgColor: const Color(0xFFFFF7ED),
              onTap: () {
                if (!Get.isRegistered<SellerProductController>()) {
                  Get.put(SellerProductController());
                }
                Get.to(() => const AddProductView());
              },
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'products',
              title: 'My Products',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF2563EB),
              iconBgColor: const Color(0xFFEFF6FF),
              onTap: () => Get.to(() => const SellerProductView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'buyer_requirements',
              title: 'Buyer Requirements',
              icon: Icons.request_quote_outlined,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFF5F3FF),
              onTap: () => Get.to(() => const SellerRfqListView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'buyer_offers',
              title: 'Buyer Offers',
              icon: Icons.local_offer_outlined,
              iconColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFECFDF5),
              onTap: () => Get.to(() => const SellerBuyerOffersView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'masters',
              title: 'Brand & Tag Master',
              icon: Icons.bookmarks_outlined,
              iconColor: const Color(0xFFDB2777),
              iconBgColor: const Color(0xFFFDF2F8),
              onTap: () => Get.to(() => const SellerMasterManagementView()),
            ),
          ],
        ),

        // ── 3. Deals & Dispatch ─────────────────────────────────
        _buyerSectionHeader(
            context, 'DEALS & DISPATCH', Icons.local_shipping_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'contracts',
              title: 'Contracts',
              icon: Icons.handshake_outlined,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              onTap: () => Get.to(() => const SellerContractsView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'consignments',
              title: 'Consignments',
              icon: Icons.inventory_outlined,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              onTap: () => Get.to(() => const SellerConsignmentsView()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'delivery_challans',
              title: 'Delivery Challans',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF059669),
              iconBgColor: const Color(0xFFECFDF5),
              onTap: () => Get.to(() => const SellerDeliveryChallanView()),
            ),
          ],
        ),

        // ── 4. Insights & Files ─────────────────────────────────
        _buyerSectionHeader(
            context, 'INSIGHTS & FILES', Icons.bar_chart_rounded),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'analytics',
              title: 'My Analytics',
              icon: Icons.analytics_outlined,
              iconColor: const Color(0xFF4F46E5),
              iconBgColor: const Color(0xFFEEF2FF),
              onTap: () => Get.toNamed(AppRoutes.myAnalytics),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'downloads',
              title: 'Downloads',
              icon: Icons.download_outlined,
              iconColor: const Color(0xFF0891B2),
              iconBgColor: const Color(0xFFECFEFF),
              onTap: () => Get.toNamed(AppRoutes.downloads),
            ),
          ],
        ),

        // ── 5. Preferences & Account ────────────────────────────
        _buyerSectionHeader(
            context, 'PREFERENCES & ACCOUNT', Icons.account_circle_outlined),
        _buyerCardGroup(
          context,
          children: [
            _buyerMenuItem(
              context: context,
              key: 'settings',
              title: 'Settings',
              icon: Icons.settings_outlined,
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF6366F1),
              iconBgColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFEEF2FF),
              onTap: () => Get.to(() => SettingsScreen()),
            ),
            _buyerDivider(context),
            _buyerMenuItem(
              context: context,
              key: 'logout',
              title: 'Log Out',
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBgColor: const Color(0xFFFEF2F2),
              onTap: _logout,
            ),
          ],
        ),

        const SizedBox(height: 10),
        Center(
          child: Text(
            'DaalSetu • Seller Portal',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
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
        _sectionLabel(context, 'ANALYTICS'),
        _analyticsMenuItem(context),
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

  Widget _analyticsMenuItem(BuildContext context) => _customMenuItem(
        context: context,
        key: 'my_analytics',
        title: 'My Analytics',
        icon: Icons.insights_outlined,
        onTap: () => Get.toNamed(AppRoutes.myAnalytics),
      );

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

  // ── BUYER REDESIGNED HELPERS ───────────────────────────────────────────────
  Widget _buyerCardGroup(BuildContext context,
      {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3B55) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buyerSectionHeader(
      BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6, top: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buyerDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF2D3B55) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buyerMenuItem({
    required BuildContext context,
    required String key,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    Widget? trailingBadge,
  }) {
    final active = activeKey == key ||
        (activeKey == 'deals' && (key == 'deals' || key == 'contracts')) ||
        (activeKey == 'buyer_offers' &&
            (key == 'deals' || key == 'offers' || key == 'today_offers'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: active
          ? (isDark
              ? AppTheme.secondaryOrange.withValues(alpha: 0.18)
              : const Color(0xFFFFF7ED))
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          _closeDrawer(context);
          onTap();
        },
        splashColor: AppTheme.secondaryOrange.withValues(alpha: 0.12),
        highlightColor: AppTheme.secondaryOrange.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (active)
                Container(
                  width: 3.5,
                  height: 22,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryOrange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.secondaryOrange.withValues(alpha: 0.15)
                      : (isDark
                          ? iconBgColor.withValues(alpha: 0.15)
                          : iconBgColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: active ? AppTheme.secondaryOrange : iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? AppTheme.secondaryOrange
                        : (isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              if (trailingBadge != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: trailingBadge,
                ),
              if (!active)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color:
                      isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawer / settings "Switch panel" action for Buyer & Seller accounts.
Future<void> switchPanelFromMenu(String panel) async {
  try {
    await PanelService.activate(panel);
  } catch (error) {
    AppSnackbar.showError(message: error.toString().replaceFirst('Exception: ', ''));
  }
}
