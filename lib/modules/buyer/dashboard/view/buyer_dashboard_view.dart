import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/glass_widgets.dart';
import '../controller/buyer_dashboard_controller.dart';
import '../../../profile/controller/profile_controller.dart';
import '../../../category/model/category_model.dart';
import '../../../category/view/category_page.dart';
import '../../orders/view/buyer_orders_view.dart';
import '../../offers/view/buyer_offers_view.dart';
import '../../offers/view/buyer_activity_view.dart';
// import '../../delivery_challan/view/buyer_delivery_challan_view.dart';
// import '../../consignment/view/buyer_consignment_view.dart';
import '../../../contracts/view/contract_view.dart';
// import '../../../seller/company/view/seller_company_view.dart';
import '../../../seller/notifications/view/seller_notification_view.dart';
import '../../../../services/realtime_notification_service.dart';
import 'buyer_dashboard_analytics.dart';
import '../../../admin_catalog/view/admin_drawer.dart';

class BuyerDashboardView extends StatelessWidget {
  BuyerDashboardView({super.key});

  final BuyerDashboardController controller = Get.put(
    BuyerDashboardController(),
  );
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AdminDrawer(activeKey: 'dashboard'),
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isError.value) {
          return RefreshIndicator(
            onRefresh: controller.fetchDashboardData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * .2),
                Icon(
                  Icons.cloud_off_outlined,
                  size: 52,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dashboard could not be loaded',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Center(
                  child: FilledButton.icon(
                    onPressed: controller.fetchDashboardData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          );
        }

        final data = controller.dashboardData.value;
        if (data == null) {
          return const Center(child: Text("No Data Found"));
        }

        return RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(context),
                const SizedBox(height: 16),
                // _buildSearchBar(context),
                // const SizedBox(height: 24),
                _buildBannerSlider(context, data.recentRfqs),
                const SizedBox(height: 30),
                _buildSectionHeader(
                  context,
                  "Shop by Category",
                  "View All",
                  onTap: () {
                    Get.to(() => CategoryPageView());
                  },
                ),
                const SizedBox(height: 16),
                _buildCategoriesList(context, controller.categories),
                const SizedBox(height: 30),
                _buildKPIGrid(context, data.kpis),
                const SizedBox(height: 30),
                Obx(
                  () => BuyerDashboardAnalytics(
                    charts: data.charts,
                    transportTracking: data.transportTracking,
                    selectedRange: controller.selectedRange.value,
                    isRangeLoading: controller.isRangeLoading.value,
                    onRangeChanged: controller.setRange,
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionHeader(
                  context,
                  "Recent Requirements & Negotiations",
                  "View All",
                  onTap: () {
                    Get.to(() => const BuyerActivityView(initialIndex: 0));
                  },
                ),
                const SizedBox(height: 16),
                _buildRecentRequirementsList(context, data.recentRfqs),
                const SizedBox(height: 30),
                _buildSectionHeader(
                  context,
                  "Recent Deals & Orders",
                  "View All",
                  onTap: () {
                    Get.to(() => const BuyerOrdersView());
                  },
                ),
                const SizedBox(height: 16),
                _buildRecentOrdersList(context, data.recentOrders),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: SizedBox(
          width: 120,
          height: 32,
          child: Image.asset(
            'assets/images/app_name.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Obx(() {
            final count = Get.isRegistered<RealtimeNotificationService>()
                ? RealtimeNotificationService.to.unreadCount.value
                : 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(IconlyLight.notification, size: 28),
                  onPressed: () => Get.to(() => const SellerNotificationView()),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          // PopupMenuButton<String>(
          //   tooltip: 'Buyer menu',
          //   onSelected: (value) {
          //     switch (value) {
          //       case 'categories':
          //         Get.to(() => const CategoryPageView());
          //         break;
          //       case 'companies':
          //         Get.to(() => const SellerCompanyView());
          //         break;
          //       case 'consignments':
          //         Get.to(() => const BuyerConsignmentView());
          //         break;
          //       case 'challans':
          //         Get.to(() => const BuyerDeliveryChallanView());
          //         break;
          //     }
          //   },
          //   itemBuilder: (_) => const [
          //     PopupMenuItem(value: 'categories', child: Text('My Categories')),
          //     PopupMenuItem(value: 'companies', child: Text('My Companies')),
          //     PopupMenuItem(
          //       value: 'consignments',
          //       child: Text('Consignment Management'),
          //     ),
          //     PopupMenuItem(
          //       value: 'challans',
          //       child: Text('Delivery Challans'),
          //     ),
          //   ],
          // ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final profile = profileController.profile.value;
      final name = profile == null
          ? "Buyer"
          : "${profile.firstName} ${profile.lastName}";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: "Hello, ",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
              children: [
                TextSpan(
                  text: name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const TextSpan(text: " 👋"),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "Welcome back! Here's what's happening today.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBannerSlider(BuildContext context, List<dynamic> rfqs) {
    final theme = Theme.of(context);

    // Find the first open RFQ to feature
    var featuredRfq = rfqs.firstWhere(
      (rfq) => rfq['status']?.toString().toLowerCase() == 'open',
      orElse: () => rfqs.isNotEmpty ? rfqs.first : null,
    );

    if (featuredRfq == null) {
      return const SizedBox(); // Hide banner if no data
    }

    String title = featuredRfq['title']?.toString() ?? "Special Deal";
    // Clean up title if it contains API-DOC prefixes
    if (title.contains("API-DOC")) {
      title = title.split(" ").skip(1).join(" ");
    }
    String price = featuredRfq['price']?.toString() ?? "";
    String qty = featuredRfq['quantity']?.toString() ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.primary.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconlyBold.discount,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "ACTIVE REQUIREMENT",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (price.isNotEmpty)
            Text(
              "₹$price",
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 4),
          if (qty.isNotEmpty)
            Text(
              "Quantity Needed: $qty",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                Get.to(() => const BuyerActivityView(initialIndex: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "View Details",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(IconlyLight.arrow_right_2, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String action, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    if (categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayCategories = categories.take(6).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: displayCategories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      IconlyBold.category,
                      size: 28,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.categoryName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @visibleForTesting
  Widget buildKPIGrid(BuildContext context, Map<String, dynamic> kpis) =>
      _buildKPIGrid(context, kpis);

  Widget _buildKPIGrid(BuildContext context, Map<String, dynamic> kpis) {
    // 1. SPENT (MTD)
    String spentVal =
        kpis['spent_mtd']?.toString() ??
        kpis['spent']?.toString() ??
        kpis['total_spent']?.toString() ??
        "0.00";
    if (!spentVal.startsWith("₹") && spentVal.isNotEmpty) {
      spentVal = "₹$spentVal";
    }
    String spentDelta =
        kpis['spent_delta']?.toString() ??
        kpis['spent_change']?.toString() ??
        "—";
    if (!spentDelta.contains("↑") &&
        !spentDelta.contains("↓") &&
        spentDelta.isNotEmpty) {
      spentDelta = "↑ $spentDelta";
    }

    // 2. ACTIVE ORDERS
    String activeOrders =
        kpis['active_orders']?.toString() ?? kpis['orders']?.toString() ?? "0";
    String openReq =
        kpis['open_rfq']?.toString() ??
        kpis['open_requirements']?.toString() ??
        kpis['active_requirements']?.toString() ??
        "0";

    // 3. ACTIVE CONTRACTS
    String activeContracts =
        kpis['active_contracts']?.toString() ??
        kpis['contracts']?.toString() ??
        kpis['total_contracts']?.toString() ??
        "0";
    String signedThisMonth =
        kpis['signed_this_month']?.toString() ??
        kpis['contracts_signed_mtd']?.toString() ??
        kpis['signed_contracts']?.toString() ??
        "0";

    // 4. IN TRANSIT
    String inTransit =
        kpis['in_transit']?.toString() ??
        kpis['transport_active']?.toString() ??
        kpis['active_transports']?.toString() ??
        "0";
    String avgEta =
        kpis['avg_eta']?.toString() ?? kpis['eta']?.toString() ?? "—";

    final paymentPending = kpis['pay_pending']?.toString() ?? '0';
    final pendingAmount = kpis['pending_amount']?.toString() ?? '₹0.00';
    final issues = kpis['issues']?.toString() ?? '0';
    final openTickets = kpis['open_tickets']?.toString() ?? '0';
    final topSupplier = kpis['top_supplier']?.toString() ?? '—';
    final supplierShare = kpis['top_supplier_share']?.toString() ?? '—';
    final rawAvgPrice = kpis['avg_price'] ??
        kpis['avg_purchase_price'] ??
        kpis['average_purchase_price'] ??
        kpis['average_price'];
    String averagePrice = '₹0.00';
    if (rawAvgPrice != null) {
      final s = rawAvgPrice.toString().trim();
      if (s.isNotEmpty && s != 'null') {
        if (s.startsWith('₹') || s.toLowerCase().contains('/qtl')) {
          averagePrice = s;
        } else {
          final numVal = double.tryParse(s.replaceAll(RegExp(r'[^\d.]'), ''));
          if (numVal != null) {
            averagePrice = '₹${numVal.toStringAsFixed(2)}/qtl';
          } else {
            averagePrice = '₹$s/qtl';
          }
        }
      }
    }
    final rawDelta = kpis['avg_price_delta'] ??
        kpis['avg_purchase_price_delta'] ??
        kpis['vs_last_month'] ??
        '—';
    final rawDeltaStr = rawDelta.toString().trim();
    final averagePriceDelta = rawDeltaStr.toLowerCase().startsWith('vs last month')
        ? rawDeltaStr
        : 'Vs last month: $rawDeltaStr';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                title: "SPENT (MTD)",
                value: spentVal,
                subtitle: spentDelta,
                icon: Icons.currency_rupee_rounded,
                isTrend: true,
                onTap: () => Get.to(() => const ContractsScreen()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKPICard(
                context,
                title: "ACTIVE ORDERS",
                value: activeOrders,
                subtitle: "Open Requirements: $openReq",
                icon: IconlyBold.buy,
                onTap: () =>
                    Get.to(() => const BuyerOffersView(initialIndex: 0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                title: "ACTIVE CONTRACTS",
                value: activeContracts,
                subtitle: "Signed this month: $signedThisMonth",
                icon: IconlyBold.document,
                onTap: () => Get.to(() => const ContractsScreen()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKPICard(
                context,
                title: "IN TRANSIT",
                value: inTransit,
                subtitle: "Avg ETA: $avgEta",
                icon: Icons.local_shipping_rounded,
                onTap: () => Get.to(
                  () => const ContractsScreen(initialFilter: 'In Transit'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                title: "PAYMENT PENDING",
                value: paymentPending,
                subtitle: pendingAmount,
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKPICard(
                context,
                title: "ISSUES / COMPLAINTS",
                value: issues,
                subtitle: "Open tickets: $openTickets",
                icon: Icons.report_problem_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                title: "TOP SUPPLIER (MTD)",
                value: topSupplier,
                subtitle: supplierShare,
                icon: Icons.storefront_outlined,
                onTap: () =>
                    Get.to(() => const BuyerOffersView(initialIndex: 0)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKPICard(
                context,
                title: "AVG PURCHASE PRICE",
                value: averagePrice,
                subtitle: averagePriceDelta,
                icon: Icons.currency_rupee_rounded,
                onTap: () =>
                    Get.to(() => const BuyerOffersView(initialIndex: 0)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    bool isTrend = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    const orangeColor = Color(0xFFEA580C);
    const peachBg = Color(0xFFFFF3EA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: peachBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: orangeColor, size: 18),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: theme.dividerColor.withValues(alpha: 0.8),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isTrend ? FontWeight.w600 : FontWeight.w500,
                color: isTrend
                    ? Colors.green.shade700
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequirementsList(
    BuildContext context,
    List<dynamic> requirements,
  ) {
    if (requirements.isEmpty) {
      return const Center(
        child: Text("No recent requirements or negotiations."),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requirements.length > 5 ? 5 : requirements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = requirements[index] is Map
            ? Map<String, dynamic>.from(requirements[index] as Map)
            : <String, dynamic>{};

        // Reference ID (e.g., #INT-20261017-1686, #RFQ-20261016-7770)
        final trackingId = (item['reference_id'] ??
                item['tracking_id'] ??
                item['rfq_id'] ??
                item['interest_id'] ??
                item['code'] ??
                item['id'] ??
                '')
            .toString()
            .trim();
        final formattedTrackingId = trackingId.isNotEmpty
            ? (trackingId.startsWith('#') ? trackingId : '#$trackingId')
            : '';

        // Product / Item name
        final itemTitle = (item['title'] ??
                item['commodity'] ??
                item['product'] ??
                item['name'] ??
                'Requirement')
            .toString()
            .trim();

        // Quantity
        final rawQty = (item['quantity'] ?? item['qty'] ?? '').toString().trim();
        final qtyStr = rawQty.isNotEmpty
            ? (rawQty.toLowerCase().contains('qtl') ? rawQty : '$rawQty qtl')
            : '';

        // Assemble Header: e.g. "#INT-20261017-1686 • teat • 50.000 qtl"
        final headerParts = [
          if (formattedTrackingId.isNotEmpty) formattedTrackingId,
          if (itemTitle.isNotEmpty) itemTitle,
          if (qtyStr.isNotEmpty) qtyStr,
        ];
        final headerTitle = headerParts.isNotEmpty
            ? headerParts.join(' • ')
            : itemTitle;

        // Best quote
        final rawPrice = (item['best_quote'] ??
                item['price'] ??
                item['rate'] ??
                item['target_price'] ??
                '')
            .toString()
            .trim();
        String quoteStr = '';
        if (rawPrice.isNotEmpty && rawPrice != '-' && rawPrice != '0') {
          if (rawPrice.startsWith('₹') || rawPrice.toLowerCase().contains('/qtl')) {
            quoteStr = rawPrice;
          } else {
            final numVal = double.tryParse(rawPrice.replaceAll(RegExp(r'[^\d.]'), ''));
            if (numVal != null) {
              quoteStr = '₹${numVal == numVal.roundToDouble() ? numVal.toInt().toString() : numVal.toStringAsFixed(1)}/qtl';
            } else {
              quoteStr = '₹$rawPrice/qtl';
            }
          }
        }

        // Seller
        final sellerVal = (item['seller_name'] ??
                item['seller'] ??
                item['seller_id'] ??
                'Broadcast')
            .toString()
            .trim();
        final sellerStr = sellerVal.isNotEmpty ? sellerVal : 'Broadcast';

        // Sub-details string
        final subParts = [
          if (quoteStr.isNotEmpty) 'Best quote: $quoteStr',
          'Seller: $sellerStr',
        ];
        final subDetails = subParts.join(' • ');

        // Status & badge color
        final status = (item['status_label'] ??
                item['status'] ??
                'Pending')
            .toString()
            .trim();
        final statusLower = status.toLowerCase();

        Color statusColor = const Color(0xFFEAB308); // Yellow/Amber Negotiation
        Color statusBg = const Color(0xFFFEF9C3);
        if (statusLower.contains('lock') || statusLower.contains('deal locked')) {
          statusColor = const Color(0xFF8B5CF6); // Purple Deal Locked
          statusBg = const Color(0xFFEDE9FE);
        } else if (statusLower.contains('confirm') ||
            statusLower.contains('accepted') ||
            statusLower.contains('closed')) {
          statusColor = const Color(0xFF10B981); // Green Confirmed
          statusBg = const Color(0xFFD1FAE5);
        } else if (statusLower.contains('open')) {
          statusColor = const Color(0xFF06B6D4); // Cyan/Teal Open
          statusBg = const Color(0xFFCFFAFE);
        } else if (statusLower.contains('reject') ||
            statusLower.contains('cancel')) {
          statusColor = const Color(0xFFEF4444); // Red
          statusBg = const Color(0xFFFEE2E2);
        }

        // Timestamp with 'Updated' prefix formatted cleanly
        final rawUpdated = (item['updated_at'] ??
                item['updated'] ??
                item['date'] ??
                '')
            .toString()
            .trim();
        String updatedText = '';
        if (rawUpdated.isNotEmpty) {
          final cleanUpdated = rawUpdated.replaceAll(RegExp(r'^Updated\s*', caseSensitive: false), '');
          // If it is an ISO string like 2026-10-17T06:00:36.437967Z
          final parsedDate = DateTime.tryParse(cleanUpdated);
          if (parsedDate != null) {
            final months = [
              '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
            ];
            final monthStr = months[parsedDate.month];
            final hour = parsedDate.hour.toString().padLeft(2, '0');
            final minute = parsedDate.minute.toString().padLeft(2, '0');
            updatedText = 'Updated ${parsedDate.day} $monthStr, $hour:$minute';
          } else {
            updatedText = 'Updated $cleanUpdated';
          }
        }

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      headerTitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (updatedText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      updatedText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                subDetails,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentOrdersList(BuildContext context, List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("No recent orders"));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length > 5 ? 5 : orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final theme = Theme.of(context);

        String status = order['transport_status'] ?? 'Pending';
        Color statusColor = Colors.orange;
        if (status.toLowerCase().contains("transit")) {
          statusColor = Colors.blue;
        }
        if (status.toLowerCase().contains("completed") ||
            status.toLowerCase().contains("delivered")) {
          statusColor = Colors.green;
        }

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.amber[100],
                child: Icon(IconlyBold.bag, color: Colors.amber[800], size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['commodity']?.toString() ?? "Commodity",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Order ID: ${order['id']}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          IconlyLight.bag,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order['quantity']?.toString() ?? "-",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          IconlyLight.calendar,
                          size: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Today",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${order['value'] ?? '0'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "per Qtl",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
