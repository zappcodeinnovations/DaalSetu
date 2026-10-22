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
import '../../admin_notifications/view/admin_notification_view.dart';
import '../../contracts/view/contract_view.dart';
import 'admin_overview_kpis_view.dart';
import '../../../utils/money_format.dart';
import '../../../widgets/app_shell.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                const SizedBox(height: 24),

                _buildSectionHeader(context, "Dashboard KPIs"),
                const SizedBox(height: 16),
                _buildKpiGrid(context, data.kpis),

                const SizedBox(height: 24),
                _buildWebGtvDealsSection(context, controller, data),

                const SizedBox(height: 24),
                _buildAnalyticsGrid(context, data.charts),

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
                  trailingText: "View All",
                  onTrailingTap: () =>
                      Get.to(() => const AdminNotificationView()),
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
                  onTrailingTap: () => Get.to(() => const ContractsScreen()),
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
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(IconlyLight.filter),
          onPressed: () => AppShell.openDrawer(activeKey: 'dashboard'),
        ),
      ),
      title: Image.asset(
        'assets/images/app_name.png',
        height: 32,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        GetBuilder<AdminNotificationController>(
          init: AdminNotificationController(),
          builder: (notifCtrl) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(IconlyLight.notification),
                  onPressed: () => Get.toNamed(AppRoutes.notifications),
                ),
                Obx(() {
                  final count = notifCtrl.unreadCount.value;
                  if (count <= 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.profile_page),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              IconlyLight.user_1,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Hello, ",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Text(" 👋", style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                IconlyBold.shield_done,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                accessLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ],
      );
    });
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
            subtitle: '↑ —',
            icon: IconlyLight.document,
            onTap: () => Get.to(() => const ContractsScreen()),
          ),
          (
            title: 'Gross Trade Value (MTD)',
            value: formatInr(kpis.gtvMtd),
            subtitle: '↑ —',
            icon: IconlyLight.graph,
            onTap: () => Get.toNamed(AppRoutes.adminBranchReports),
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
            subtitle: '↓ —',
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
          (
            title: 'Open Complaints',
            value: '${kpis.openComplaints}',
            subtitle: 'Escalations: 0',
            icon: IconlyLight.info_circle,
            onTap: () => Get.toNamed(AppRoutes.adminComplaints),
          ),
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
            onTap: () => Get.toNamed(AppRoutes.adminBranchReports),
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
            childAspectRatio: columns == 2 ? 1.12 : 1.2,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
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
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context, ChartsModel charts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1 & 2: Pipeline by Stage & Commodity Mix (Responsive row / column for small screens)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            const pipelineColors = [
              Color(0xFFF4B400),
              Color(0xFFF05A28),
              Color(0xFFD9481A),
              Color(0xFF3BAA4A),
            ];
            const commodityColors = [
              Color(0xFF059669), // Emerald
              Color(0xFF0D9488), // Teal
              Color(0xFFEA580C), // Orange
              Color(0xFF7C3AED), // Violet
              Color(0xFFDB2777), // Pink
              Color(0xFF2563EB), // Royal Blue
            ];

            if (isNarrow) {
              return Column(
                children: [
                  _buildDonutCard(
                    context,
                    "Pipeline by Stage",
                    "Deals in negotiation & signed",
                    charts.pipelineByStage.labels,
                    charts.pipelineByStage.values,
                    customColors: pipelineColors,
                  ),
                  const SizedBox(height: 12),
                  _buildDonutCard(
                    context,
                    "Commodity Mix (Volume)",
                    "Volume distribution by crop",
                    charts.commodityMix.labels,
                    charts.commodityMix.volumes,
                    customColors: commodityColors,
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
                    "Deal progress by current stage",
                    charts.pipelineByStage.labels,
                    charts.pipelineByStage.values,
                    customColors: pipelineColors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDonutCard(
                    context,
                    "Commodity Mix (Volume)",
                    "Volume distribution by commodity",
                    charts.commodityMix.labels,
                    charts.commodityMix.volumes,
                    customColors: commodityColors,
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
    final maxValue = values.fold<double>(1, (max, value) => math.max(max, value));
    final axisMax = (maxValue * 1.2).ceilToDouble();

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

  Widget _buildDonutCard(
    BuildContext context,
    String title,
    String subtitle,
    List<String> labels,
    List<int> values, {
    List<Color>? customColors,
  }) {
    final theme = Theme.of(context);
    final isCommodity = title.toLowerCase().contains('commodity');
    final colors =
        customColors ??
        [
          theme.colorScheme.primary,
          Colors.orangeAccent,
          Colors.redAccent,
          Colors.purpleAccent,
          Colors.blueAccent,
          Colors.teal,
        ];

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
    final maxValue = values.fold<int>(1, (max, value) => value > max ? value : max);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: theme.dividerColor.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: isCommodity ? 0 : 38,
                    sections: List.generate(labels.length, (index) {
                      return PieChartSectionData(
                        value: values[index].toDouble(),
                        color: colors[index % colors.length],
                        radius: isCommodity
                            ? 30 + (values[index] / maxValue) * 24
                            : 32,
                        showTitle: false,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(math.min(labels.length, 4), (index) {
                    final percent = total == 0
                        ? 0
                        : (values[index] / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    labels[index],
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${percent.toInt()}%",
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
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
      final trend =
          controller.dashboardData.value?.charts.gtvDeals ?? data.charts.gtvDeals;
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
    final gtvMax = gtvLakhs.fold<double>(1, (max, value) => math.max(max, value));
    final dealsMax = deals.fold<double>(1, (max, value) => math.max(max, value));
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
                    maxY: dealsMax * 1.2,
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
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        axisNameWidget: Text(
                          'Deals',
                          style: GoogleFonts.inter(fontSize: 9),
                        ),
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
                  right: 30,
                  bottom: 28,
                  child: IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: gtvMax * 1.2,
                        lineTouchData: const LineTouchData(enabled: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: Text(
                              '₹ Lakhs',
                              style: GoogleFonts.inter(fontSize: 9),
                            ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
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
                      "ID: ${contract.id}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${contract.seller} → ${contract.buyer}",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color,
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
                        fontSize: 9,
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
                      activity.description,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                activity.time,
                style: GoogleFonts.inter(
                  fontSize: 8,
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
