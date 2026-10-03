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
import '../../admin_catalog/view/admin_drawer.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());
  final ProfileController profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      drawer: const AdminDrawer(),
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

                _buildSectionHeader(context, "Overview KPIs", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildKpiGrid(context, data.kpis),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Performance Insights"),
                const SizedBox(height: 16),
                _buildPerformanceInsights(context, data.kpis),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "GTV & Deals Trend", trailingText: "This Month"),
                const SizedBox(height: 16),
                _buildGtvDealsChart(context, data.charts.gtvDeals),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Analytics Overview"),
                const SizedBox(height: 16),
                _buildAnalyticsGrid(context, data.charts),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Branch Performance",
                  trailingText: "View All",
                  onTrailingTap: () => Get.toNamed(AppRoutes.adminBranchReports),
                ),
                const SizedBox(height: 16),
                _buildBranchPerformance(context, data.branchPerformance),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Recent Contracts", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildRecentContracts(context, data.recentContracts),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Recent Activity", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildRecentActivity(context, data.recentActivities),

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
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Image.asset(
        'assets/images/app_name.png',
        height: 32,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(IconlyLight.notification),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.deepOrange,
                  shape: BoxShape.circle,
                ),
                child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.profile_page),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(IconlyLight.user_1, size: 16, color: Theme.of(context).colorScheme.primary),
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
      final name = profile == null ? "Admin" : "${profile.firstName} ${profile.lastName}";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Hello, ",
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              Text(
                name,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              const Text(" 👋", style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(IconlyBold.shield_done, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                "Super Admin Access",
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? trailingText, VoidCallback? onTrailingTap}) {
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

  Widget _buildKpiGrid(BuildContext context, KpiModel kpis) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildDynamicMetricCard(context, "GTV MTD", "₹${kpis.gtvMtd}", "Total Value", IconlyLight.graph),
          const SizedBox(width: 12),
          _buildDynamicMetricCard(context, "Brokerage", "₹${kpis.brokerageEarnedMtd}", "Earned MTD", IconlyLight.wallet),
          const SizedBox(width: 12),
          _buildDynamicMetricCard(context, "Contracts", kpis.activeContracts.toString(), "Active", IconlyLight.document),
          const SizedBox(width: 12),
          _buildDynamicMetricCard(context, "Pending", kpis.pendingDispatches.toString(), "Dispatches", IconlyLight.time_circle),
          const SizedBox(width: 12),
          _buildDynamicMetricCard(context, "Complaints", kpis.openComplaints.toString(), "Open Issues", IconlyLight.info_circle),
        ],
      ),
    );
  }

  Widget _buildPerformanceInsights(BuildContext context, KpiModel kpis) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildPerformanceCard(context, "Sellers", kpis.activeSellers.toString(), "Active", true),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, "Buyers", kpis.activeBuyers.toString(), "Active", true),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, "Transporters", kpis.activeTransporters.toString(), "Active", true),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, "OTD %", "${kpis.otdPercent}%", "On-Time", true),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, "Transit", "${kpis.avgTransitDays}", "Avg Days", false),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, String title, String value, String change, bool isPositive) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(isPositive ? IconlyBold.arrow_up : IconlyBold.arrow_down, size: 8, color: isPositive ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text(change, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicMetricCard(BuildContext context, String title, String value, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context, ChartsModel charts) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDonutCard(context, "Pipeline", "Stages", charts.pipelineByStage.labels, charts.pipelineByStage.values)),
            const SizedBox(width: 12),
            Expanded(child: _buildDonutCard(context, "Commodity", "Mix", charts.commodityMix.labels, charts.commodityMix.volumes)),
          ],
        ),
      ],
    );
  }

  Widget _buildDonutCard(BuildContext context, String title, String subtitle, List<String> labels, List<int> values) {
    final theme = Theme.of(context);
    final colors = [theme.colorScheme.primary, Colors.orangeAccent, Colors.redAccent, Colors.purpleAccent, Colors.blueAccent, Colors.teal];
    
    if (labels.isEmpty || values.isEmpty) {
       return GlassCard(
         padding: const EdgeInsets.all(12),
         child: const SizedBox(height: 110, child: Center(child: Text("No Data"))),
       );
    }
    
    final total = values.fold<int>(0, (sum, item) => sum + item);

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 20,
                    sections: List.generate(labels.length, (index) {
                      return PieChartSectionData(
                        value: values[index].toDouble(),
                        color: colors[index % colors.length],
                        radius: 12,
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
                    final percent = total == 0 ? 0 : (values[index] / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Expanded(child: Text(labels[index], style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          Text("${percent.toInt()}%", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
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

  Widget _buildGtvDealsChart(BuildContext context, GtvDealsChart data) {
    final theme = Theme.of(context);
    if (data.labels.isEmpty) return const SizedBox();

    double maxY = data.gtvValues.isNotEmpty ? data.gtvValues.reduce((a, b) => a > b ? a : b) : 10;
    if (maxY == 0) maxY = 10;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem("₹${rod.toY.toInt()}", const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
                }
              )
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < data.labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(data.labels[value.toInt()], style: TextStyle(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: maxY / 5 > 0 ? maxY / 5 : 10,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text("${(value / 1000).toInt()}k", style: TextStyle(fontSize: 8, color: theme.textTheme.bodyMedium?.color));
                  }
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: theme.dividerColor.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4])),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.labels.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data.gtvValues[index],
                    color: theme.colorScheme.primary,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchPerformance(BuildContext context, List<BranchPerformanceModel> branches) {
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
        if (branch.status.toUpperCase().contains("WATCHLIST")) statusColor = Colors.orange;
        if (branch.status.toUpperCase().contains("CRITICAL")) statusColor = Colors.red;

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
                child: Icon(IconlyLight.location, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text("Admin: ${branch.admin}", style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${branch.gtvMtd}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(branch.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentContracts(BuildContext context, List<ContractModel> contracts) {
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
                child: Icon(IconlyLight.document, color: theme.colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ID: ${contract.id}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text("${contract.seller} → ${contract.buyer}", style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(contract.commodity, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(contract.paymentStatus.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<ActivityModel> activities) {
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
                child: const Icon(IconlyLight.notification, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text(activity.description, style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(activity.time, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
        );
      },
    );
  }
}
