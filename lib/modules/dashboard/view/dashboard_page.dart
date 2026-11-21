import 'package:daalsetu/widgets/dashboard_period_bar.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controller/dashboard_controller.dart';
import '../model/dashboard_model.dart';
import '../../profile/controller/profile_controller.dart';
import '../../../theme/glass_widgets.dart';
import '../../../routes/app_routes.dart';
import '../../admin_notifications/controller/admin_notification_controller.dart';
import '../../contracts/view/contract_view.dart';
import '../../nav_bar/controller/nav_controller.dart';
import 'admin_overview_kpis_view.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/app_shell.dart';
import '../../../widgets/hero_header.dart';
import '../../../theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  static void _navigateToContracts() {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().changeIndex(1);
    } else {
      Get.to(() => const ContractsScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.dashboardData.value;
        if (data == null) return const Center(child: Text("No Data Found"));

        return RefreshIndicator(
          onRefresh: controller.fetchDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context),
                const SizedBox(height: 14),
                DashboardPeriodBar(onChanged: controller.fetchDashboard),
                const SizedBox(height: 10),

                _buildSectionHeader(context, "Dashboard KPIs"),
                const SizedBox(height: 16),
                _buildKpiGrid(context, data.kpis),

                const SizedBox(height: 24),
                _buildWebGtvDealsSection(context, controller, data),

                const SizedBox(height: 24),
                _buildAnalyticsGrid(context, data.charts, data.kpis),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Branch Performance",
                  trailingText: "View All",
                  onTrailingTap: () =>
                      Get.toNamed(AppRoutes.adminBranchReports),
                ),
                const SizedBox(height: 16),
                _buildBranchPerformance(context, data.branchPerformance),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Recent Activities",
                ),
                const SizedBox(height: 16),
                _buildRecentActivity(context, data.recentActivities),

                const SizedBox(height: 24),
                _buildWebPaymentsChart(
                  context,
                  data.charts.paymentsReceivables,
                ),

                const SizedBox(height: 24),
                _buildWebUserDistributionChart(
                  context,
                  data.charts.userDistribution,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Recent Contracts",
                  trailingText: "View All",
                  onTrailingTap: _navigateToContracts,
                ),
                const SizedBox(height: 16),
                _buildRecentContracts(context, data.recentContracts),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return HeroHeader(
      leading: Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Open navigation menu',
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          onPressed: () => AppShell.openDrawer(activeKey: 'dashboard'),
        ),
      ),
      titleWidget: SizedBox(
        width: 120,
        height: 32,
        child: Image.asset(
          'assets/images/app_name.png',
          fit: BoxFit.contain,
          color: Colors.white,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GetBuilder<AdminNotificationController>(
            init: AdminNotificationController(),
            builder: (notifCtrl) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(IconlyLight.notification, color: Colors.white),
                    onPressed: () => Get.toNamed(AppRoutes.notifications),
                  ),
                  Obx(() {
                    final count = notifCtrl.unreadCount.value;
                    if (count <= 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile_page),
            child: Obx(() {
              final profile = profileController.profile.value;
              final imgUrl = profile != null
                  ? profileController.profileImageUrl(profile.profileImage)
                  : '';
              return Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      imgUrl.isNotEmpty ? NetworkImage(imgUrl) : null,
                  child: imgUrl.isEmpty
                      ? const Icon(IconlyLight.user_1, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final profile = profileController.profile.value;
      final name = profile == null
          ? "Admin"
          : "${profile.firstName} ${profile.lastName}".trim();
      final normalizedRole =
          profile?.role
              .trim()
              .toLowerCase()
              .replaceAll('-', '_')
              .replaceAll(' ', '_') ??
          '';
      final accessLabel = normalizedRole == 'super_admin'
          ? 'Super Admin Access'
          : 'Admin Access';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Builder(builder: (context) {
              final imgUrl = profile != null
                  ? profileController.profileImageUrl(profile.profileImage)
                  : '';
              if (imgUrl.isNotEmpty) {
                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF9800), width: 2),
                    image: DecorationImage(
                      image: NetworkImage(imgUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(IconlyBold.shield_done, color: Colors.white, size: 20),
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Hello, ",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE65100),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(" 👋", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accessLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  // Same identity line as the web dashboard: Name, Branch Code and Location.
                  ..._identityLines(context, controller.dashboardData.value, fallbackName: name),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _identityLines(BuildContext context, DashboardModel? data, {required String fallbackName}) {
    final theme = Theme.of(context);
    final style = GoogleFonts.inter(
      fontSize: 12,
      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
    );
    final name = (data?.identityName ?? '').isNotEmpty ? data!.identityName : fallbackName;
    final rows = <(String, String)>[
      ('Name', name),
      ('Branch Code', (data?.branchCode ?? '').isNotEmpty ? data!.branchCode : 'N/A'),
      ('Location', (data?.branchLocation ?? '').isNotEmpty ? data!.branchLocation : 'N/A'),
    ];
    return [
      const SizedBox(height: 6),
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text.rich(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: '${row.$1}: '),
                TextSpan(text: row.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ];
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? trailingText,
    VoidCallback? onTrailingTap,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        if (trailingText != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                trailingText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Numbers as the web dashboard prints them (JavaScript): 20.0 -> "20", 2.4 -> "2.4".
  static String _webNum(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return double.parse(value.toStringAsFixed(2)).toString();
  }

  // Same cards, sub-lines and number formats as the web admin dashboard.
  Widget _buildKpiGrid(BuildContext context, KpiModel kpis) {
    final metrics =
        <
          ({
            String title,
            String value,
            String subtitle,
            IconData icon,
            VoidCallback? onTap,
          })
        >[
          (
            title: 'Active Contracts',
            value: '${kpis.activeContracts}',
            subtitle: 'In negotiation: ${kpis.dealsInNegotiation}',
            icon: IconlyLight.document,
            onTap: _navigateToContracts,
          ),
          (
            title: 'Gross Trade Value (MTD)',
            value: formatInr(kpis.gtvMtd),
            subtitle: 'Finalized deals: ${kpis.finalDealsMtd}',
            icon: IconlyLight.graph,
            onTap: _navigateToContracts,
          ),
          (
            title: 'Brokerage Earned (MTD)',
            value: formatInr(kpis.brokerageEarnedMtd),
            subtitle: 'Avg brokerage: ${_webNum(kpis.brokerageRate)}%',
            icon: IconlyLight.wallet,
            onTap: () => Get.toNamed(AppRoutes.adminBrokerageBills),
          ),
          (
            title: 'Pending Dispatches',
            value: '${kpis.pendingDispatches}',
            subtitle: 'On-time delivery: ${_webNum(kpis.otdPercent)}%',
            icon: IconlyLight.time_circle,
            onTap: () => Get.toNamed(AppRoutes.adminDeliveryChallans),
          ),
          (
            title: 'Active Sellers',
            value: '${kpis.activeSellers}',
            subtitle: 'Commodities listed: ${kpis.listedSkus}',
            icon: IconlyLight.bag,
            onTap: () => Get.to(
              () =>
                  AdminOverviewKpisView(kpis: kpis, initialCategory: 'Network'),
            ),
          ),
          (
            title: 'Active Buyers',
            value: '${kpis.activeBuyers}',
            subtitle: 'Finalized deals (MTD): ${kpis.finalDealsMtd}',
            icon: IconlyLight.user_1,
            onTap: () => Get.to(
              () =>
                  AdminOverviewKpisView(kpis: kpis, initialCategory: 'Network'),
            ),
          ),
          // Open Complaints is switched off (kept, commented out, in case it comes back).
          // (
          //   title: 'Open Complaints',
          //   value: '${kpis.openComplaints}',
          //   subtitle: 'Escalations: ${kpis.escalations}',
          //   icon: IconlyLight.info_circle,
          //   onTap: () => Get.toNamed(AppRoutes.adminComplaints),
          // ),
          (
            title: 'On-time Delivery %',
            value: '${_webNum(kpis.otdPercent)}%',
            subtitle: 'Avg transit: ${_webNum(kpis.avgTransitDays)} days',
            icon: IconlyLight.send,
            onTap: () => Get.to(
              () => AdminOverviewKpisView(
                kpis: kpis,
                initialCategory: 'Logistics',
              ),
            ),
          ),
          (
            title: 'Payments Overdue',
            value: '${kpis.paymentsOverdue}',
            subtitle: '₹ at risk: ₹${(kpis.atRiskAmount / 100000).toStringAsFixed(1)}L',
            icon: IconlyLight.paper,
            onTap: () => Get.toNamed(AppRoutes.adminBrokerageBills),
          ),
          (
            title: 'Active Transporters',
            value: '${kpis.activeTransporters}',
            subtitle: 'Capacity utilized: ${_webNum(kpis.capacityUtilized)}%',
            icon: IconlyLight.location,
            onTap: () => Get.to(
              () => AdminOverviewKpisView(
                kpis: kpis,
                initialCategory: 'Logistics',
              ),
            ),
          ),
          (
            title: 'Branches',
            value: '${kpis.branches}',
            subtitle: 'Admins active: ${kpis.adminsActive}',
            icon: IconlyLight.category,
            // Same as the web card: the branch requests page.
            onTap: () => Get.toNamed(AppRoutes.adminModule('branch_requests')),
          ),
          (
            title: 'Deals in Negotiation',
            value: '${kpis.dealsInNegotiation}',
            subtitle: 'Avg time-to-close: ${_webNum(kpis.avgTtcDays)} days',
            icon: IconlyLight.swap,
            onTap: () => Get.toNamed(AppRoutes.adminContracts),
          ),
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 480
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // Fixed height that fits the modernized card's content comfortably
            mainAxisExtent: 144,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _buildDynamicMetricCard(
              context,
              metric.title,
              metric.value,
              metric.subtitle,
              metric.icon,
              width: double.infinity,
              onTap: metric.onTap,
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceInsights(BuildContext context, KpiModel kpis) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildPerformanceCard(
            context,
            "Sellers",
            kpis.activeSellers.toString(),
            "Active",
            true,
            onTap: () => Get.to(
              () =>
                  AdminOverviewKpisView(kpis: kpis, initialCategory: 'Network'),
            ),
          ),
          const SizedBox(width: 12),
          _buildPerformanceCard(
            context,
            "Buyers",
            kpis.activeBuyers.toString(),
            "Active",
            true,
            onTap: () => Get.to(
              () =>
                  AdminOverviewKpisView(kpis: kpis, initialCategory: 'Network'),
            ),
          ),
          const SizedBox(width: 12),
          _buildPerformanceCard(
            context,
            "Transporters",
            kpis.activeTransporters.toString(),
            "Active",
            true,
            onTap: () => Get.to(
              () => AdminOverviewKpisView(
                kpis: kpis,
                initialCategory: 'Logistics',
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildPerformanceCard(
            context,
            "OTD %",
            "${kpis.otdPercent % 1 == 0 ? kpis.otdPercent.toInt() : kpis.otdPercent}%",
            "On-Time",
            true,
            onTap: () => Get.to(
              () => AdminOverviewKpisView(
                kpis: kpis,
                initialCategory: 'Logistics',
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildPerformanceCard(
            context,
            "Transit",
            "${kpis.avgTransitDays}",
            "Avg Days",
            false,
            onTap: () => Get.to(
              () => AdminOverviewKpisView(
                kpis: kpis,
                initialCategory: 'Logistics',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @visibleForTesting
  Widget buildPerformanceInsights(BuildContext context, KpiModel kpis) =>
      _buildPerformanceInsights(context, kpis);

  Widget _buildPerformanceCard(
    BuildContext context,
    String title,
    String value,
    String change,
    bool isPositive, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? IconlyBold.arrow_up : IconlyBold.arrow_down,
                    size: 8,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    change,
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, Color bg}) _getKpiPalette(String title) {
    final t = title.toLowerCase();
    if (t.contains('contract')) {
      return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED));
    }
    if (t.contains('gross') || t.contains('gtv') || t.contains('trade')) {
      return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
    }
    if (t.contains('brokerage')) {
      return (color: const Color(0xFF059669), bg: const Color(0xFFECFDF5));
    }
    if (t.contains('dispatch') || t.contains('delivery')) {
      return (color: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF));
    }
    if (t.contains('seller')) {
      return (color: const Color(0xFF7C3AED), bg: const Color(0xFFF5F3FF));
    }
    if (t.contains('buyer')) {
      return (color: const Color(0xFF0D9488), bg: const Color(0xFFF0FDFA));
    }
    if (t.contains('complaint') || t.contains('issue')) {
      return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2));
    }
    if (t.contains('payment') || t.contains('overdue') || t.contains('risk')) {
      return (color: const Color(0xFFE11D48), bg: const Color(0xFFFFF1F2));
    }
    if (t.contains('transporter')) {
      return (color: const Color(0xFF4F46E5), bg: const Color(0xFFEEF2FF));
    }
    if (t.contains('branch')) {
      return (color: const Color(0xFF0F766E), bg: const Color(0xFFCCFBF1));
    }
    if (t.contains('negotiation')) {
      return (color: const Color(0xFFF57C00), bg: const Color(0xFFFFF7ED));
    }
    return (color: const Color(0xFFEA580C), bg: const Color(0xFFFFF7ED));
  }

  Widget _buildDynamicMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon, {
    double width = 120,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = _getKpiPalette(title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark
                          ? palette.bg.withValues(alpha: 0.15)
                          : palette.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: palette.color.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: palette.color,
                    ),
                  ),
                  if (onTap != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : palette.bg.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: palette.color,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid(
    BuildContext context,
    ChartsModel charts, [
    KpiModel? kpis,
  ]) {
    final pipelineLabels = List<String>.from(charts.pipelineByStage.labels);
    final pipelineValues = List<int>.from(charts.pipelineByStage.values);

    // Synchronize Deals in Negotiation count with authoritative live KPI
    if (kpis != null && kpis.dealsInNegotiation > 0) {
      final negIdx = pipelineLabels.indexWhere(
        (l) => l.trim().toLowerCase().contains('negotiat'),
      );
      if (negIdx != -1) {
        if (pipelineValues[negIdx] < kpis.dealsInNegotiation) {
          pipelineValues[negIdx] = kpis.dealsInNegotiation;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1 & 2: Pipeline by Stage & Commodity Mix (Responsive column for phone, row for tablet/desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (isNarrow) {
              return Column(
                children: [
                  _buildDonutCard(
                    context,
                    "Pipeline by Stage",
                    "Deals in negotiation & signed",
                    pipelineLabels,
                    pipelineValues,
                    colorResolver: resolvePipelineStageColor,
                  ),
                  const SizedBox(height: 12),
                  _buildDonutCard(
                    context,
                    "Commodity Mix (Volume)",
                    "Volume distribution by crop",
                    charts.commodityMix.labels,
                    charts.commodityMix.volumes,
                    colorResolver: resolveCommodityColor,
                    showValues: true,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDonutCard(
                    context,
                    "Pipeline by Stage",
                    "Deals in negotiation & signed",
                    pipelineLabels,
                    pipelineValues,
                    colorResolver: resolvePipelineStageColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDonutCard(
                    context,
                    "Commodity Mix (Volume)",
                    "Volume distribution by crop",
                    charts.commodityMix.labels,
                    charts.commodityMix.volumes,
                    colorResolver: resolveCommodityColor,
                    showValues: true,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // 3: Top Buyers (GTV)
        _buildWebTopBuyersChart(context, charts.topBuyers),
        const SizedBox(height: 14),

        // 4: Transporter SLA
        _buildWebTransporterSlaChart(context, charts.transporterSla),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildWebTopBuyersChart(
    BuildContext context,
    TopBuyersChart topBuyers,
  ) {
    final theme = Theme.of(context);
    final count = math.min(topBuyers.labels.length, topBuyers.gtvValues.length);
    final values = topBuyers.gtvValues.take(count).map((v) => v / 100000).toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce(math.max);
    final axisMax = math.max(1.0, (maxValue * 1.2).ceilToDouble());

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Buyers (GTV)',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          if (count == 0)
            const SizedBox(
              height: 150,
              child: Center(child: Text('No buyer trade data available')),
            )
          else
            ...List.generate(count, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        topBuyers.labels[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (values[index] / axisMax).clamp(0.03, 1.0),
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9C83E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${values[index].toStringAsFixed(2)}L',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWebTransporterSlaChart(
    BuildContext context,
    TransporterSlaChart sla,
  ) {
    final theme = Theme.of(context);
    final count = math.min(sla.labels.length, sla.otdPercentages.length);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transporter SLA',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: count == 0
                ? const Center(child: Text('No transporter SLA data available'))
                : BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 100,
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${sla.otdPercentages[groupIndex].toStringAsFixed(0)}% on-time',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= count) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 76,
                                  child: Text(
                                    sla.labels[index],
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.45),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(count, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: sla.otdPercentages[index].clamp(0.0, 100.0),
                              width: count > 4 ? 20 : 48,
                              color: const Color(0xFF4CC9A6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildTopBuyersSummary(BuildContext context, TopBuyersChart topBuyers) {
    final theme = Theme.of(context);
    final labels = topBuyers.labels;
    final values = topBuyers.gtvValues;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.leaderboard_rounded,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Top Buyers (GTV)",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "Highest volume trading partners",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${labels.length} Buyers",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (labels.isEmpty || values.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No buyer trade data available",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            )
          else ...[
            ...List.generate(labels.length, (index) {
              final buyerName = labels[index];
              final gtv = values[index];
              final maxVal = values.fold<double>(
                0.0,
                (prev, val) => math.max(prev, val),
              );
              final progress = maxVal > 0
                  ? (gtv / maxVal).clamp(0.05, 1.0)
                  : 0.05;

              final gtvText = gtv >= 100000
                  ? "₹${(gtv / 100000).toStringAsFixed(2)} L"
                  : "₹${gtv.toStringAsFixed(0)}";

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Colors.amber.withOpacity(0.2)
                                    : (theme.textTheme.bodyMedium?.color ??
                                              Colors.grey)
                                          .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "#${index + 1}",
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? Colors.amber[800]
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                buyerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          gtvText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            (theme.textTheme.bodyMedium?.color ?? Colors.grey)
                                .withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          index == 0 ? Colors.amber : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget buildTransporterSlaSummary(
    BuildContext context,
    TransporterSlaChart transporterSla,
  ) {
    final theme = Theme.of(context);
    final labels = transporterSla.labels;
    final otdList = transporterSla.otdPercentages;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Transporter SLA",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "On-time delivery performance",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "SLA Target: 90%",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (labels.isEmpty || otdList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No transporter SLA data recorded",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            )
          else ...[
            ...List.generate(labels.length, (index) {
              final name = labels[index];
              final otd = otdList[index];
              final progress = (otd / 100.0).clamp(0.0, 1.0);
              final isTargetMet = otd >= 90;
              final slaColor = isTargetMet
                  ? const Color(0xFF10B981)
                  : (otd >= 70 ? Colors.orange : Colors.redAccent);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: slaColor,
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: slaColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${otd.toStringAsFixed(0)}% On-Time",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: slaColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor:
                            (theme.textTheme.bodyMedium?.color ?? Colors.grey)
                                .withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(slaColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildWebPaymentsChart(
    BuildContext context,
    PaymentsReceivablesChart payments,
  ) {
    final theme = Theme.of(context);
    const receivedColor = Color(0xFF4CC9A6);
    const outstandingColor = Color(0xFFF5B342);
    final labels = payments.labels;
    final values = List<double>.generate(labels.length, (index) {
      final received = index < payments.received.length
          ? payments.received[index] / 100000
          : 0.0;
      final outstanding = index < payments.outstanding.length
          ? payments.outstanding[index] / 100000
          : 0.0;
      return received + outstanding;
    });
    final highest = values.isEmpty
        ? 1.0
        : values.fold<double>(1.0, (max, value) => math.max(max, value));

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments & Receivables',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          _chartLegend(const [
            ('Received (₹ Lakhs)', receivedColor),
            ('Outstanding (₹ Lakhs)', outstandingColor),
          ], theme),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: labels.isEmpty
                ? Center(
                    child: Text(
                      'No payment data available',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: highest * 1.2,
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final received = groupIndex < payments.received.length
                                ? payments.received[groupIndex] / 100000
                                : 0.0;
                            final outstanding = groupIndex < payments.outstanding.length
                                ? payments.outstanding[groupIndex] / 100000
                                : 0.0;
                            return BarTooltipItem(
                              'Received: ₹${received.toStringAsFixed(2)}L\nOutstanding: ₹${outstanding.toStringAsFixed(2)}L',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 58,
                                  child: Text(
                                    labels[index],
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.45),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(labels.length, (index) {
                        final received = index < payments.received.length
                            ? payments.received[index] / 100000
                            : 0.0;
                        final outstanding = index < payments.outstanding.length
                            ? payments.outstanding[index] / 100000
                            : 0.0;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: received + outstanding,
                              width: labels.length > 6 ? 12 : 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                              rodStackItems: [
                                BarChartRodStackItem(0, received, receivedColor),
                                BarChartRodStackItem(
                                  received,
                                  received + outstanding,
                                  outstandingColor,
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebUserDistributionChart(
    BuildContext context,
    UserDistributionChart users,
  ) {
    final theme = Theme.of(context);
    const colors = [
      Color(0xFFF4B400),
      Color(0xFF3BAA4A),
      Color(0xFFFFC107),
      Color(0xFFF05A28),
      Color(0xFF2C2C2C),
    ];
    final itemCount = math.min(users.labels.length, users.counts.length);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Distribution',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          if (itemCount == 0)
            SizedBox(
              height: 190,
              child: Center(
                child: Text(
                  'No user distribution data available',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 190,
                height: 190,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 48,
                    sectionsSpace: 0,
                    sections: List.generate(itemCount, (index) {
                      return PieChartSectionData(
                        value: users.counts[index].toDouble(),
                        color: colors[index % colors.length],
                        radius: 38,
                        showTitle: false,
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _chartLegend(
              List.generate(
                itemCount,
                (index) => (
                  users.labels[index],
                  colors[index % colors.length],
                ),
              ),
              theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _chartLegend(
    List<(String, Color)> items,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              item.$1,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget buildPaymentsReceivablesSummary(
    BuildContext context,
    PaymentsReceivablesChart payments,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labels = payments.labels.isNotEmpty
        ? payments.labels
        : ['Current (0-15D)', '16-30 Days', '31-60 Days', 'Overdue 60D+'];
    final received = payments.received.isNotEmpty
        ? payments.received
        : [540000.0, 180000.0, 0.0, 0.0];
    final outstanding = payments.outstanding.isNotEmpty
        ? payments.outstanding
        : [180000.0, 0.0, 0.0, 0.0];

    final totalReceived = received.fold(0.0, (sum, val) => sum + val);
    final totalOutstanding = outstanding.fold(0.0, (sum, val) => sum + val);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      IconlyLight.wallet,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Payments & Receivables",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "Aging analysis & cashflow health",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Cashflow Active",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Stats Comparison Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF10B981,
                    ).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Settled / Received",
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹${(totalReceived / 100000).toStringAsFixed(2)} L",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF59E0B,
                    ).withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Pending / Aging",
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "₹${(totalOutstanding / 100000).toStringAsFixed(2)} L",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Aging Buckets Breakdown
          ...List.generate(labels.length, (index) {
            final label = labels[index];
            final recVal = index < received.length ? received[index] : 0.0;
            final outVal = index < outstanding.length
                ? outstanding[index]
                : 0.0;
            final bracketTotal = recVal + outVal;
            final progress = bracketTotal > 0
                ? (recVal / bracketTotal).clamp(0.0, 1.0)
                : 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "Rec: ₹${(recVal / 1000).toInt()}k  |  Out: ₹${(outVal / 1000).toInt()}k",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(
                        0xFFF59E0B,
                      ).withValues(alpha: 0.35),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildUserDistributionSummary(
    BuildContext context,
    UserDistributionChart userDist,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final labels = userDist.labels.isNotEmpty
        ? userDist.labels
        : ['Sellers', 'Buyers', 'Transporters'];
    final counts = userDist.counts.isNotEmpty ? userDist.counts : [1, 1, 1];
    final total = counts.fold<int>(0, (sum, count) => sum + count);

    final roleColors = [
      const Color(0xFFF59E0B), // Sellers - Amber
      const Color(0xFF3B82F6), // Buyers - Blue
      const Color(0xFFA855F7), // Transporters - Purple
    ];

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      IconlyLight.user,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Stakeholder Ecosystem",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        "User distribution by trading role",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$total Total Users",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-Segment Bar
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: List.generate(labels.length, (index) {
                    final count = index < counts.length ? counts[index] : 0;
                    final flex = count > 0 ? count : 1;
                    final color = roleColors[index % roleColors.length];
                    return Expanded(
                      flex: flex,
                      child: Container(color: color),
                    );
                  }),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Role Badges & Details Grid
          Row(
            children: List.generate(labels.length, (index) {
              final label = labels[index];
              final count = index < counts.length ? counts[index] : 0;
              final percent = total > 0
                  ? ((count / total) * 100).toStringAsFixed(0)
                  : "0";
              final color = roleColors[index % roleColors.length];

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < labels.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$count",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        "$percent% Share",
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  static Color resolvePipelineStageColor(String label, int index) {
    final lower = label.toLowerCase().trim();
    // The four admin pipeline stages use the web dashboard's colours, so both match.
    if (lower.contains('negotiat')) {
      return const Color(0xFFF4B400); // Amber
    } else if (lower.contains('seller') && lower.contains('confirm')) {
      return const Color(0xFFF05A28); // Orange-red (was green, a copy of Deal Confirmed)
    } else if (lower.contains('buyer') && lower.contains('confirm')) {
      return const Color(0xFF8B5CF6); // Violet
    } else if (lower == 'deal confirmed') {
      return const Color(0xFF3BAA4A); // Green
    } else if (lower.contains('sign') || lower.contains('contract')) {
      return const Color(0xFF2563EB); // Royal Blue
    } else if (lower.contains('buyer') || lower.contains('pending')) {
      return const Color(0xFF6366F1); // Indigo
    } else if (lower.contains('deal') || lower.contains('confirm') || lower.contains('won') || lower.contains('close')) {
      return const Color(0xFF10B981); // Emerald Green (Success)
    } else if (lower.contains('dispatch') || lower.contains('transit')) {
      return const Color(0xFF06B6D4); // Cyan
    } else if (lower.contains('cancel') || lower.contains('lost') || lower.contains('reject')) {
      return const Color(0xFFEF4444); // Crimson Red
    }
    const fallbackPipelineColors = [
      Color(0xFFF59E0B), // Amber
      Color(0xFF2563EB), // Royal Blue
      Color(0xFF10B981), // Emerald Green
      Color(0xFF6366F1), // Indigo
      Color(0xFF06B6D4), // Cyan
      Color(0xFF8B5CF6), // Violet
    ];
    return fallbackPipelineColors[index % fallbackPipelineColors.length];
  }

  static Color resolveCommodityColor(String label, int index) {
    final lower = label.toLowerCase().trim();
    if (lower.contains('split') || lower.contains('yellow') || lower.contains('chana')) {
      return const Color(0xFFCA8A04); // Golden Mustard
    } else if (lower.contains('chilka') || lower.contains('moong')) {
      return const Color(0xFF0F766E); // Deep Teal / Sea Green
    } else if (lower.contains('organic')) {
      return const Color(0xFFC2410C); // Terracotta Rust
    } else if (lower.contains('polish')) {
      return const Color(0xFF7E22CE); // Deep Amethyst Purple
    } else if (lower.contains('toor') || lower.contains('arhar')) {
      return const Color(0xFFE11D48); // Rose Crimson
    } else if (lower.contains('urad') || lower.contains('black')) {
      return const Color(0xFF334155); // Slate Charcoal
    } else if (lower.contains('masoor') || lower.contains('red')) {
      return const Color(0xFFEA580C); // Warm Orange
    }
    // Dedicated commodity palette - distinct from pipeline stages
    const fallbackCommodityColors = [
      Color(0xFF0F766E), // Deep Teal
      Color(0xFF7E22CE), // Purple
      Color(0xFFCA8A04), // Mustard
      Color(0xFFC2410C), // Terracotta
      Color(0xFFE11D48), // Rose
      Color(0xFF334155), // Slate Charcoal
      Color(0xFF059669), // Emerald
      Color(0xFFD97706), // Amber
      Color(0xFF9333EA), // Violet
      Color(0xFF0284C7), // Sky Blue
      Color(0xFF475569), // Cool Grey
    ];
    return fallbackCommodityColors[index % fallbackCommodityColors.length];
  }

  Widget _buildDonutCard(
    BuildContext context,
    String title,
    String subtitle,
    List<String> labels,
    List<int> values, {
    List<Color>? customColors,
    Color Function(String label, int index)? colorResolver,
    // true: the legend shows each slice's real figure (e.g. 327), like the web card, not its percentage.
    bool showValues = false,
  }) {
    final theme = Theme.of(context);
    final fallbackColors = customColors ?? [
      theme.colorScheme.primary,
      Colors.orangeAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.teal,
      Colors.indigo,
    ];

    Color getColor(int index) {
      if (colorResolver != null && index < labels.length) {
        return colorResolver(labels[index], index);
      }
      return fallbackColors[index % fallbackColors.length];
    }
    if (labels.isEmpty || values.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(12),
        child: const SizedBox(
          height: 110,
          child: Center(child: Text("No Data")),
        ),
      );
    }

    final total = values.fold<int>(0, (sum, item) => sum + item);

    // Compute normalized integer percentages that strictly sum to 100% (Largest Remainder Method)
    final List<int> roundedPercentages = List<int>.filled(labels.length, 0);
    if (total > 0) {
      final List<double> remainders = [];
      int currentSum = 0;
      for (int i = 0; i < values.length; i++) {
        final p = (values[i] / total) * 100.0;
        final floorVal = p.floor();
        roundedPercentages[i] = floorVal;
        remainders.add(p - floorVal);
        currentSum += floorVal;
      }
      int diff = 100 - currentSum;
      if (diff > 0) {
        final order = List<int>.generate(values.length, (i) => i);
        order.sort((a, b) => remainders[b].compareTo(remainders[a]));
        for (int i = 0; i < diff && i < order.length; i++) {
          roundedPercentages[order[i]]++;
        }
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 90,
                width: 90,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 24,
                    sections: List.generate(labels.length, (index) {
                      return PieChartSectionData(
                        value: values[index].toDouble(),
                        color: getColor(index),
                        radius: 16,
                        showTitle: false,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(labels.length, (index) {
                    final itemColor = getColor(index);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: itemColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              labels[index],
                              maxLines: 2,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyLarge?.color,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            showValues ? '${values[index]}' : "${roundedPercentages[index]}%",
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: itemColor),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebGtvDealsSection(
    BuildContext context,
    DashboardController controller,
    DashboardModel data,
  ) {
    return Obx(() {
      if (controller.isUpdatingTrend.value) {
        return const GlassCard(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      }
      final charts = controller.dashboardData.value?.charts ?? data.charts;
      // The selected filter's series; older servers only send the monthly one.
      final period = controller.selectedGtvPeriod.value.toUpperCase();
      final rangeKey = charts.gtvDealsRanges.keys
          .where(period.startsWith)
          .firstOrNull;
      final trend = rangeKey != null ? charts.gtvDealsRanges[rangeKey]! : charts.gtvDeals;
      return _buildWebGtvDealsChart(context, trend, controller);
    });
  }

  Widget buildLegacyGtvDealsSection(
    BuildContext context,
    DashboardController controller,
    DashboardModel data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "GTV & Deals Trend",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Obx(
              () => InkWell(
                onTap: () => _showPeriodFilterDialog(context, controller),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.selectedGtvPeriod.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isUpdatingTrend.value) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final gtvDeals =
              controller.dashboardData.value?.charts.gtvDeals ??
              data.charts.gtvDeals;
          return buildLegacyGtvDealsChart(
            context,
            gtvDeals,
          );
        }),
      ],
    );
  }

  void _showPeriodFilterDialog(
    BuildContext context,
    DashboardController controller,
  ) {
    final periods = [
      '7D (Week)',
      '1M (This Month)',
      '3M (Quarter)',
      '1Y (Year)',
    ];
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    "Select Time Period",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const Divider(),
                ...periods.map((p) {
                  return Obx(() {
                    final currentVal = controller.selectedGtvPeriod.value;
                    final isSelected =
                        currentVal == p ||
                        (p.contains('1M') &&
                            (currentVal == 'This Month' ||
                                currentVal == '1M')) ||
                        (p.contains('7D') &&
                            (currentVal == 'This Week' ||
                                currentVal == '7D')) ||
                        (p.contains('3M') &&
                            (currentVal == 'This Quarter' ||
                                currentVal == '3M')) ||
                        (p.contains('1Y') &&
                            (currentVal == 'This Year' || currentVal == '1Y'));
                    return ListTile(
                      title: Text(
                        p,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        controller.updateGtvPeriod(p);
                      },
                    );
                  });
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _emptyAxisLabel(double value, TitleMeta meta) => const SizedBox.shrink();

  Widget _buildWebGtvDealsChart(
    BuildContext context,
    GtvDealsChart data,
    DashboardController controller,
  ) {
    final theme = Theme.of(context);
    final count = math.min(
      data.labels.length,
      math.min(data.gtvValues.length, data.dealsValues.length),
    );
    if (count == 0) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          height: 220,
          child: Center(child: Text('No trade trend data available')),
        ),
      );
    }

    final labels = data.labels.take(count).toList();
    final gtvLakhs = data.gtvValues.take(count).map((value) => value / 100000).toList();
    final deals = data.dealsValues.take(count).map((value) => value.toDouble()).toList();

    // Scale to the data, matching web portal (7D view scale 0 - 0.07 with peak at ~0.065 Lakhs)
    final gtvPeak = gtvLakhs.fold<double>(0, (max, value) => math.max(max, value));
    final double gtvTop;
    final double gtvInterval;
    if (gtvPeak <= 0.07) {
      gtvTop = 0.07;
      gtvInterval = 0.01;
    } else if (gtvPeak <= 0.5) {
      gtvTop = 0.5;
      gtvInterval = 0.1;
    } else if (gtvPeak <= 1.0) {
      gtvTop = 1.0;
      gtvInterval = 0.2;
    } else {
      gtvTop = (gtvPeak * 1.15).ceilToDouble();
      gtvInterval = gtvTop / 5;
    }

    final maxDeals = deals.fold<double>(0, (max, value) => math.max(max, value));
    final double dealsTop;
    final double dealsInterval;
    if (maxDeals <= 1.0) {
      dealsTop = 1.0;
      dealsInterval = 0.2;
    } else if (maxDeals <= 5.0) {
      dealsTop = 5.0;
      dealsInterval = 1.0;
    } else {
      dealsTop = maxDeals.ceilToDouble();
      dealsInterval = math.max(1, (dealsTop / 5).ceil()).toDouble();
    }

    String lakhsLabel(double v) {
      if (v <= 0.0001) return '0';
      if (gtvTop <= 0.1) return v.toStringAsFixed(2);
      if (gtvTop <= 1.0) return v.toStringAsFixed(2);
      if (gtvTop < 10) return v.toStringAsFixed(1);
      return v.toStringAsFixed(0);
    }
    const gtvColor = Color(0xFFEA7C1C);
    const dealsColor = Color(0xFF4CC9A6);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gross Trade Value & Deals',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              for (final range in const ['7D', '1M', '3M', '1Y'])
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => controller.updateGtvPeriod(range),
                    borderRadius: BorderRadius.circular(7),
                    child: Obx(() {
                      final selected = controller.selectedGtvPeriod.value
                          .toUpperCase()
                          .startsWith(range);
                      return Container(
                        constraints: const BoxConstraints(minWidth: 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFF05A28)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFF05A28)
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.55,
                                  ),
                          ),
                        ),
                        child: Text(
                          range,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          _chartLegend(const [
            ('GTV (₹ Lakhs)', gtvColor),
            ('Deals Closed', dealsColor),
          ], theme),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    maxY: dealsTop,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${deals[groupIndex].toInt()} deals',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      // Mirror the LineChart's left axis layout for pixel-perfect plot synchronization
                      leftTitles: AxisTitles(
                        axisNameWidget: Text(
                          '₹ Lakhs',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: Colors.transparent,
                          ),
                        ),
                        sideTitles: const SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: _emptyAxisLabel,
                        ),
                      ),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text(
                          'Deals',
                          style: GoogleFonts.inter(fontSize: 9),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: dealsInterval,
                          getTitlesWidget: (value, meta) {
                            if (value < -0.01 || value > dealsTop + 0.01) {
                              return const SizedBox.shrink();
                            }
                            if (dealsTop <= 1.0) {
                              return Text(
                                value <= 0.0001 ? '0' : value.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              );
                            }
                            return value % 1 != 0
                                ? const SizedBox.shrink()
                                : Text(
                                    value.toInt().toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Text(
                                labels[index],
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(count, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: deals[index],
                            width: count > 8 ? 10 : 18,
                            color: dealsColor.withValues(alpha: 0.82),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: gtvTop,
                        minX: -0.5,
                        maxX: count - 0.5,
                        lineTouchData: const LineTouchData(enabled: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // Mirror BarChart right axis layout for identical plot rectangle
                          rightTitles: AxisTitles(
                            axisNameWidget: Text(
                              'Deals',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.transparent,
                              ),
                            ),
                            sideTitles: const SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: _emptyAxisLabel,
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: _emptyAxisLabel,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              '₹ Lakhs',
                              style: GoogleFonts.inter(fontSize: 9),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: gtvInterval,
                              getTitlesWidget: (value, meta) => Text(
                                lakhsLabel(value),
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: theme.dividerColor.withValues(alpha: 0.45),
                            strokeWidth: 1,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              count,
                              (index) => FlSpot(index.toDouble(), gtvLakhs[index]),
                            ),
                            isCurved: true,
                            curveSmoothness: 0.25,
                            color: gtvColor,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: gtvColor.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLegacyGtvDealsChart(
    BuildContext context,
    GtvDealsChart data, [
    String period = '1M (This Month)',
  ]) {
    final theme = Theme.of(context);
    if (data.labels.isEmpty) return const SizedBox();

    List<String> labels = List<String>.from(data.labels);
    List<double> gtvValues = List<double>.from(data.gtvValues);

    final norm = period.toLowerCase();
    if (norm.contains('7d') || norm.contains('week')) {
      final now = DateTime.now();
      labels = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return "${d.day}/${d.month}";
      });
      final total = gtvValues.isNotEmpty ? gtvValues.last : 720000.0;
      gtvValues = [
        total * 0.05,
        total * 0.10,
        total * 0.15,
        total * 0.20,
        total * 0.25,
        total * 0.15,
        total * 0.10,
      ];
    } else if (norm.contains('1m') || norm.contains('this month')) {
      labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      final total = gtvValues.isNotEmpty ? gtvValues.last : 720000.0;
      gtvValues = [total * 0.15, total * 0.25, total * 0.35, total * 0.25];
    } else if (norm.contains('3m') || norm.contains('quarter')) {
      if (labels.length >= 3) {
        labels = labels.sublist(labels.length - 3);
        gtvValues = gtvValues.sublist(gtvValues.length - 3);
      }
    } else if (norm.contains('1y') || norm.contains('year')) {
      // 1 Year: full months list from API
    }

    double maxY = gtvValues.isNotEmpty
        ? gtvValues.reduce((a, b) => a > b ? a : b)
        : 10;
    if (maxY == 0) maxY = 10;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.25,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    "₹${rod.toY.toInt()}",
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          labels[value.toInt()],
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: maxY / 4 > 0 ? maxY / 4 : 10,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    // Small values used to all read "0k".
                    return Text(
                      compactInr(value),
                      style: TextStyle(
                        fontSize: 8,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (val) => FlLine(
                color: theme.dividerColor.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(labels.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: gtvValues[index],
                    color: theme.colorScheme.primary,
                    width: labels.length > 7 ? 6 : 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchPerformance(
    BuildContext context,
    List<BranchPerformanceModel> branches,
  ) {
    if (branches.isEmpty) return const Text("No branch data.");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: branches.length > 5 ? 5 : branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final branch = branches[index];
        final theme = Theme.of(context);

        Color statusColor = Colors.green;
        if (branch.status.toUpperCase().contains("WATCHLIST"))
          statusColor = Colors.orange;
        if (branch.status.toUpperCase().contains("CRITICAL"))
          statusColor = Colors.red;

        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyLight.location,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Admin: ${branch.admin}",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatInr(branch.gtvMtd),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      branch.status.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8,
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

  Widget _buildRecentContracts(
    BuildContext context,
    List<ContractModel> contracts,
  ) {
    if (contracts.isEmpty) return const Text("No recent contracts.");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contracts.length > 5 ? 5 : contracts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final theme = Theme.of(context);

        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconlyLight.document,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${contract.seller} → ${contract.buyer}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (contract.bagCount.trim().isNotEmpty)
                          '${contract.bagCount} bags',
                        if (contract.packingWeightKg.trim().isNotEmpty)
                          '${contract.packingWeightKg} kg',
                        if (contract.quantity.trim().isNotEmpty)
                          contract.quantity,
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    contract.commodity,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      contract.paymentStatus.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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

  Widget _buildRecentActivity(
    BuildContext context,
    List<ActivityModel> activities,
  ) {
    if (activities.isEmpty) return const Text("No recent activity.");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length > 5 ? 5 : activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        final theme = Theme.of(context);
        final cleanedDesc = activity.description
            .replaceAll(RegExp(r'\.{2,}\s*•'), ' •')
            .replaceAll(RegExp(r'\.{2,}$'), '')
            .replaceAll('  ', ' ')
            .trim();

        return GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyLight.notification,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cleanedDesc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.4,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activity.time,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
