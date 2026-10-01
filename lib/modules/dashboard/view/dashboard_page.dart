import 'package:agro_broker/modules/users/view/user_view.dart';
import 'package:agro_broker/modules/dashboard/model/dashboard_model.dart';
import 'package:agro_broker/modules/profile/controller/profile_controller.dart';
import 'package:agro_broker/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../admin_catalog/view/admin_drawer.dart';
import 'package:agro_broker/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  static const Color primaryBlue = AppTheme.primaryGold;
  static const Color accentYellow = AppTheme.secondaryOrange;
  static const Color accentGreen = AppTheme.successGreen;
  static const Color accentRed = AppTheme.errorRed;
  static const Color textWhite = AppTheme.textPrimary;
  static const Color textGrey = AppTheme.textMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 20,
        centerTitle: false,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        title: Builder(
          builder: (context) {
            final theme = Theme.of(context);

            return Row(
              children: [
                /// 🔵 Left Icon Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                /// 👋 Greeting + Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hey 👋",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
  
                      Obx(() {
                        final profile = profileController.profile.value;
  
                        if (profile == null) {
                          return Text(
                            "Loading...",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
  
                        return Row(
                          children: [
                            Flexible(
                              child: Text(
                                "${profile.firstName} ${profile.lastName}",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        /// 🔔 Right Side Actions
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).iconTheme.color,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Get.toNamed(AppRoutes.profile_page);
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      // bottomNavigationBar: _buildBottomNavBar(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   backgroundColor: primaryBlue,
      //   child: const Icon(Icons.add, size: 30),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        final data = controller.dashboardData.value;

        if (data == null) {
          return const Center(
            child: Text("No Data Found", style: TextStyle(color: textWhite)),
          );
        }

        return RefreshIndicator(
          color: primaryBlue,
          backgroundColor: theme.cardColor,
          onRefresh: controller.fetchDashboard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// KPI GRID SECTION
                _buildExpandableKpiSection(context, data.kpis),

                const SizedBox(height: 20),

                /// USERS MANAGEMENT SECTION
                _buildAllUsersCard(context),

                const SizedBox(height: 24),

                /// CHARTS SECTION
                _buildBarChartSection(
                  context: context,
                  title: "GTV vs Deals Trend",
                  chartData: data.charts.gtvDeals,
                ),

                const SizedBox(height: 20),

                _buildDonutChartSection(
                  context: context,
                  title: "Pipeline Stages",
                  chartData: data.charts.pipelineByStage,
                ),

                const SizedBox(height: 30),

                _buildCommodityMixSection(
                  context: context,
                  chartData: data.charts.commodityMix,
                ),

                const SizedBox(height: 30),

                _buildTopBuyersSection(
                  context: context,
                  chartData: data.charts.topBuyers,
                ),

                const SizedBox(height: 30),

                _buildTransporterSlaSection(
                  context: context,
                  chartData: data.charts.transporterSla,
                ),

                const SizedBox(height: 30),

                _buildPaymentsSection(
                  context: context,
                  chartData: data.charts.paymentsReceivables,
                ),

                const SizedBox(height: 30),

                _buildUserDistributionSection(
                  context: context,
                  chartData: data.charts.userDistribution,
                ),

                const SizedBox(height: 16),

                /// BRANCH PERFORMANCE
                _sectionHeader(
                  context,
                  "Branch Performance",
                  Icons.location_city,
                ),

                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.branchPerformance.length,
                  itemBuilder: (context, index) {
                    final branch = data.branchPerformance[index];
                    return _buildBranchRow(context, branch);
                  },
                ),

                const SizedBox(height: 30),

                /// RECENT CONTRACTS
                _sectionHeaderWithAction(
                  context,
                  "Recent Contracts",
                  "VIEW ALL",
                ),

                const SizedBox(height: 16),

                _buildRecentContractsTable(context, data.recentContracts),

                const SizedBox(height: 30),

                /// RECENT ACTIVITIES
                _sectionHeader(context, "Recent Activity", null),

                const SizedBox(height: 16),

                Builder(
                  builder: (context) {
                    final theme = Theme.of(context);

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.recentActivities.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          final activity = data.recentActivities[index];

                          final isVerification = index == 0;
                          final isAlert = index == 1;

                          return _buildTimelineItem(
                            context: context,
                            title: activity.title,
                            time: activity.time,
                            subtext: activity.description,
                            icon: isVerification
                                ? Icons.verified
                                : (isAlert
                                      ? Icons.warning_amber
                                      : Icons.person_add),
                            iconColor: isVerification
                                ? theme.colorScheme.primary
                                : (isAlert
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.primary),
                            isLast: index == data.recentActivities.length - 1,
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// ===============================
  /// WIDGET BUILDERS
  /// ===============================

  Widget _sectionHeader(BuildContext context, String title, IconData? icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeaderWithAction(
    BuildContext context,
    String title,
    String action,
  ) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          action,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableKpiSection(BuildContext context, KpiModel kpi) {
    final theme = Theme.of(context);

    return Obx(() {
      final showAll = controller.isKpiExpanded.value;

      final allKpis = [
        _kpiItem(
          context,
          "Active Contracts",
          kpi.activeContracts,
          Icons.description_outlined,
          Colors.blue,
        ),
        _kpiItem(
          context,
          "GTV MTD",
          "₹${kpi.gtvMtd}",
          Icons.trending_up,
          Colors.green,
        ),
        _kpiItem(
          context,
          "Brokerage MTD",
          "₹${kpi.brokerageEarnedMtd}",
          Icons.account_balance_wallet_outlined,
          Colors.orange,
        ),
        _kpiItem(
          context,
          "Open Complaints",
          kpi.openComplaints,
          Icons.warning_amber_rounded,
          Colors.red,
        ),

        _kpiItem(
          context,
          "Brokerage Rate",
          "${kpi.brokerageRate}%",
          Icons.percent,
          Colors.purple,
        ),
        _kpiItem(
          context,
          "Pending Dispatch",
          kpi.pendingDispatches,
          Icons.local_shipping_outlined,
          Colors.teal,
        ),
        _kpiItem(
          context,
          "Active Sellers",
          kpi.activeSellers,
          Icons.storefront_outlined,
          Colors.indigo,
        ),
        _kpiItem(
          context,
          "Listed SKUs",
          kpi.listedSkus,
          Icons.inventory_2_outlined,
          Colors.cyan,
        ),
        _kpiItem(
          context,
          "Active Buyers",
          kpi.activeBuyers,
          Icons.shopping_cart_outlined,
          Colors.deepOrange,
        ),
        _kpiItem(
          context,
          "Final Deals",
          kpi.finalDealsMtd,
          Icons.handshake_outlined,
          Colors.green,
        ),
        _kpiItem(
          context,
          "OTD %",
          "${kpi.otdPercent}%",
          Icons.timer_outlined,
          Colors.amber,
        ),
        _kpiItem(
          context,
          "Avg Transit",
          kpi.avgTransitDays,
          Icons.route_outlined,
          Colors.blueGrey,
        ),
        _kpiItem(
          context,
          "Payments Overdue",
          kpi.paymentsOverdue,
          Icons.money_off_csred_outlined,
          Colors.redAccent,
        ),
        _kpiItem(
          context,
          "At Risk Amount",
          "₹${kpi.atRiskAmount}",
          Icons.report_problem_outlined,
          Colors.red,
        ),
        _kpiItem(
          context,
          "Transporters",
          kpi.activeTransporters,
          Icons.local_shipping,
          Colors.teal,
        ),
        _kpiItem(
          context,
          "Capacity Used",
          "${kpi.capacityUtilized}%",
          Icons.speed_outlined,
          Colors.lightBlue,
        ),
        _kpiItem(
          context,
          "Branches",
          kpi.branches,
          Icons.location_city_outlined,
          Colors.indigo,
        ),
        _kpiItem(
          context,
          "Admins Active",
          kpi.adminsActive,
          Icons.admin_panel_settings_outlined,
          Colors.deepPurple,
        ),
        _kpiItem(
          context,
          "Deals Negotiation",
          kpi.dealsInNegotiation,
          Icons.balance_outlined,
          Colors.orange,
        ),
        _kpiItem(
          context,
          "Avg TTC Days",
          kpi.avgTtcDays,
          Icons.schedule_outlined,
          Colors.grey,
        ),
      ];

      final visibleCount = showAll ? allKpis.length : 4;

      return Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: allKpis.take(visibleCount).toList(),
          ),

          const SizedBox(height: 20),

          /// 🔽 Expand / Collapse Arrow
          Center(
            child: GestureDetector(
              onTap: controller.toggleKpi,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: AnimatedRotation(
                  turns: showAll ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 28,
                    color: theme.iconTheme.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _kpiItem(
    BuildContext context,
    String title,
    dynamic value,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 18),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: theme.iconTheme.color?.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBarChartSection({
    required BuildContext context,
    required String title,
    required GtvDealsChart chartData,
  }) {
    final theme = Theme.of(context);

    final labels = chartData.labels;
    final gtvValues = chartData.gtvValues;

    if (labels.isEmpty || gtvValues.isEmpty) {
      return _emptyChartCard(context, title);
    }

    final maxY = gtvValues.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 10 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: maxY == 0 ? 2 : maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withOpacity(0.4),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: theme.cardColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "₹${rod.toY.toStringAsFixed(0)}",
                        TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),

                barGroups: List.generate(labels.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: gtvValues[index],
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
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

  Widget _emptyChartCard(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Text("No data available", style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildDonutChartSection({
    required BuildContext context,
    required String title,
    required PipelineChart chartData,
  }) {
    final theme = Theme.of(context);

    final labels = chartData.labels;
    final values = chartData.values;

    if (labels.isEmpty || values.isEmpty) {
      return _emptyChartCard(context, title);
    }

    final total = values.fold<int>(0, (sum, item) => sum + item);

    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          /// 🔥 DONUT CHART
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 60,
                sectionsSpace: 3,
                sections: List.generate(labels.length, (index) {
                  final value = values[index].toDouble();
                  final percent = total == 0 ? 0 : (value / total) * 100;

                  return PieChartSectionData(
                    value: value,
                    title: "${percent.toStringAsFixed(0)}%",
                    color: colors[index % colors.length],
                    radius: 60,
                    titleStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 LEGEND
          Column(
            children: List.generate(labels.length, (index) {
              final percent = total == 0 ? 0 : (values[index] / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chartLegend(
                      context,
                      labels[index],
                      colors[index % colors.length],
                    ),
                    Text(
                      "${percent.toStringAsFixed(0)}%",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCommodityMixSection({
    required BuildContext context,
    required CommodityMixChart chartData,
  }) {
    final theme = Theme.of(context);

    final labels = chartData.labels;
    final volumes = chartData.volumes;

    if (labels.isEmpty || volumes.isEmpty) {
      return _emptyChartCard(context, "Commodity Mix");
    }

    final total = volumes.fold<int>(0, (sum, item) => sum + item);

    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Commodity Mix",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          /// Donut Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 50,
                sectionsSpace: 3,
                sections: List.generate(labels.length, (index) {
                  final percent = total == 0
                      ? 0
                      : (volumes[index] / total) * 100;

                  return PieChartSectionData(
                    value: volumes[index].toDouble(),
                    title: "${percent.toStringAsFixed(0)}%",
                    color: colors[index % colors.length],
                    radius: 55,
                    titleStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// Legend
          Column(
            children: List.generate(labels.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chartLegend(
                      context,
                      labels[index],
                      colors[index % colors.length],
                    ),
                    Text(
                      volumes[index].toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBuyersSection({
    required BuildContext context,
    required TopBuyersChart chartData,
  }) {
    final theme = Theme.of(context);

    final labels = chartData.labels;
    final values = chartData.gtvValues;

    if (labels.isEmpty || values.isEmpty) {
      return _emptyChartCard(context, "Top Buyers");
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Buyers (By GTV)",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Column(
            children: List.generate(labels.length, (index) {
              final percent = maxValue == 0 ? 0.0 : values[index] / maxValue;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${index + 1}. ${labels[index]}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₹${values[index].toStringAsFixed(0)}",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: theme.dividerColor.withOpacity(0.4),
                        color: theme.colorScheme.primary,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildBranchRow(BuildContext context, dynamic branch) {
    final theme = Theme.of(context);

    Color statusColor = theme.textTheme.bodySmall!.color!;
    String statusText = branch.status.toUpperCase();

    if (statusText.contains("ACTIVE")) {
      statusColor = theme.colorScheme.secondary;
    } else if (statusText.contains("WATCHLIST")) {
      statusColor = Colors.orange;
    } else if (statusText.contains("CRITICAL")) {
      statusColor = theme.colorScheme.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      branch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Admin: ${branch.admin}",
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text("GTV", style: theme.textTheme.bodySmall),
                Text(
                  "₹${branch.gtvMtd}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: theme.iconTheme.color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTransporterSlaSection({
    required BuildContext context,
    required TransporterSlaChart chartData,
  }) {
    final theme = Theme.of(context);

    final labels = chartData.labels;
    final percentages = chartData.otdPercentages;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transporter SLA (On-Time Delivery)",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Column(
            children: List.generate(labels.length, (index) {
              final percent = percentages[index] / 100;

              Color progressColor = theme.colorScheme.secondary;

              if (percentages[index] < 90) {
                progressColor = Colors.orange;
              }
              if (percentages[index] < 85) {
                progressColor = theme.colorScheme.error;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          labels[index],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${percentages[index]}%",
                          style: TextStyle(
                            color: progressColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      backgroundColor: theme.dividerColor.withOpacity(0.4),
                      color: progressColor,
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection({
    required BuildContext context,
    required PaymentsReceivablesChart chartData,
  }) {
    final theme = Theme.of(context);

    return Obx(() {
      final labels = chartData.labels;
      final showAll = controller.isPaymentsExpanded.value;

      final visibleCount = showAll
          ? labels.length
          : (labels.length >= 2 ? 2 : labels.length);

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payments & Receivables",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              children: List.generate(visibleCount, (index) {
                final received = chartData.received[index];
                final outstanding = chartData.outstanding[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labels[index],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Received: ₹${received.toStringAsFixed(0)}",
                          style: TextStyle(color: theme.colorScheme.secondary),
                        ),
                        Text(
                          "Outstanding: ₹${outstanding.toStringAsFixed(0)}",
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            if (labels.length > 2)
              Center(
                child: GestureDetector(
                  onTap: controller.togglePayments,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: AnimatedRotation(
                      turns: showAll ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: theme.iconTheme.color,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildUserDistributionSection({
    required BuildContext context,
    required UserDistributionChart chartData,
  }) {
    final theme = Theme.of(context);
    final labels = chartData.labels;
    final values = chartData.counts;

    if (labels.isEmpty || values.isEmpty) {
      return _emptyChartCard(context, "User Distribution");
    }

    final total = values.fold<int>(0, (sum, item) => sum + item);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.orange,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("User Distribution", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: List.generate(labels.length, (index) {
                  final percent = total == 0 ? 0 : (values[index] / total) * 100;
                  return PieChartSectionData(
                    value: values[index].toDouble(),
                    title: "${percent.toStringAsFixed(0)}%",
                    color: colors[index % colors.length],
                    radius: 50,
                    titleStyle: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(labels.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chartLegend(context, labels[index], colors[index % colors.length]),
                    Text("${values[index]}", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentContractsTable(BuildContext context, List contracts) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    "ID",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "PARTIES",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "COMMODITY",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "VAL",
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contracts.length > 5 ? 5 : contracts.length,
            separatorBuilder: (c, i) =>
                Divider(height: 1, color: theme.dividerColor),
            itemBuilder: (context, index) {
              final contract = contracts[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        contract.id.replaceAll("Contract ", "#"),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.seller,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "vs ${contract.buyer}",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        contract.commodity,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                     Text(
                       "${contract.value.isNotEmpty ? contract.value : '—'}",
                       style: theme.textTheme.bodyMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required String title,
    required String subtext,
    required String time,
    required IconData icon,
    required Color iconColor,
    required bool isLast,
  }) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: theme.cardColor,
                  radius: 12,
                  child: Icon(icon, color: iconColor, size: 14),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.dividerColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$time • $subtext",
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final theme = Theme.of(context);
    return BottomAppBar(
      color: theme.cardColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.grid_view, "Dashboard", true),
            _navItem(Icons.description_outlined, "Contracts", false),
            const SizedBox(width: 48), // Space for FAB
            _navItem(Icons.map_outlined, "Branches", false),
            _navItem(Icons.settings_outlined, "Settings", false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isSelected ? primaryBlue : textGrey, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryBlue : textGrey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

Widget _buildAllUsersCard(BuildContext context) {
  final theme = Theme.of(context);

  return GestureDetector(
    onTap: () {
      // Get.toNamed(AppRoutes.users);
      Get.to(() => UserScreen());
    },
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🔵 Icon Container
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 16),

          /// 📄 Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Users",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage & View All Registered Users",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          /// ➡ Arrow
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 18,
            color: theme.iconTheme.color,
          ),
        ],
      ),
    ),
  );
}
