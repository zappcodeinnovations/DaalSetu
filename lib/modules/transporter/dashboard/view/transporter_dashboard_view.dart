import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controller/transporter_dashboard_controller.dart';
import '../../company/view/transporter_company_form.dart';
import '../../company/controller/transporter_company_controller.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../routes/app_routes.dart';

class TransporterDashboardView extends StatelessWidget {
  TransporterDashboardView({super.key});

  final TransporterDashboardController controller = Get.put(TransporterDashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return RefreshIndicator(
          onRefresh: controller.fetchDashboardOverview,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context),
                const SizedBox(height: 24),
                
                _buildSectionHeader(context, "Today's Overview", trailing: _buildDateBadge(context, controller.dateStr.value)),
                const SizedBox(height: 16),
                _buildTodaysOverview(context),
                
                const SizedBox(height: 24),
                _buildSectionHeader(context, "Analytics Overview", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildAnalyticsGrid(context),

                const SizedBox(height: 24),
                _buildRegisterBanner(context),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Quick Actions", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildQuickActions(context),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Performance Insights", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildPerformanceInsights(context),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Monthly Revenue Overview", trailing: _buildDropdownBadge(context, "This Year")),
                const SizedBox(height: 16),
                _buildMonthlyRevenueChart(context),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Recent Activity", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildRecentActivity(context),

                const SizedBox(height: 100), // Bottom nav padding
              ],
            ),
          ),
        );
      }),
    );
  }

  // --- App Bar ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(IconlyLight.filter), // Hamburger substitute
        onPressed: () {},
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
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(IconlyLight.user_1, size: 16, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // --- Hero Section ---
  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
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
              controller.username.value,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const Text(" 👋", style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(IconlyBold.location, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              controller.branchName.value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(width: 4),
            Icon(IconlyLight.arrow_down_2, size: 14, color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ],
    );
  }

  // --- Helper: Section Header ---
  Widget _buildSectionHeader(BuildContext context, String title, {String? trailingText, Widget? trailing}) {
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
          Text(
            trailingText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          )
        else if (trailing != null)
          trailing,
      ],
    );
  }

  Widget _buildDateBadge(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildDropdownBadge(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
        const SizedBox(width: 4),
        Icon(IconlyLight.arrow_down_2, size: 14, color: theme.textTheme.bodyMedium?.color),
      ],
    );
  }

  // --- Today's Overview ---
  Widget _buildTodaysOverview(BuildContext context) {
    return Obx(() {
      if (controller.dynamicKpis.isEmpty) {
        if (controller.isLoading.value) {
          return const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()));
        } else {
          return const SizedBox();
        }
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: controller.dynamicKpis.map((kpi) {
            IconData icon = IconlyLight.document;
            if (kpi.screen.toLowerCase().contains('deliver')) icon = IconlyLight.paper;
            if (kpi.screen.toLowerCase().contains('vehicle')) icon = IconlyLight.location;
            if (kpi.screen.toLowerCase().contains('driver')) icon = IconlyLight.user_1;
            
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildDynamicMetricCard(context, kpi, icon),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildDynamicMetricCard(BuildContext context, KpiItem metric, IconData icon) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 120, // Slightly wider to fit dynamic titles
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
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 4),
            Text(
              metric.value.toString(),
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 4),
            Text(
              metric.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  // --- Analytics Grid ---
  Widget _buildAnalyticsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTrendChartCard(context)),
            const SizedBox(width: 12),
            Expanded(child: _buildDonutCard(context, "Delivery Status", "This Month", controller.deliveryStatus)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildDonutCard(context, "Transport Types", "This Month", controller.transportTypes, colors: [Theme.of(context).colorScheme.primary, Colors.orangeAccent, Colors.redAccent])),
            const SizedBox(width: 12),
            Expanded(child: _buildTopRoutesCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.earningsTrend.value;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Earnings & Shipments Trend", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          Text("This Week", style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text("₹ 18,60,000", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
              const SizedBox(width: 4),
              const Icon(IconlyBold.arrow_up, size: 8, color: Colors.green),
              Text(" 15.2%", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 14,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.labels.length) {
                          return Text(data.labels[value.toInt()], style: TextStyle(fontSize: 6, color: theme.textTheme.bodyMedium?.color));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(radius: 2, color: theme.colorScheme.primary, strokeWidth: 1, strokeColor: Colors.white);
                    }),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary.withOpacity(0.3), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutCard(BuildContext context, String title, String subtitle, List<DonutItem> items, {List<Color>? colors}) {
    final theme = Theme.of(context);
    final finalColors = colors ?? [Colors.green, Colors.orange, Colors.red];
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
                    sections: items.asMap().entries.map((e) {
                      return PieChartSectionData(
                        value: e.value.percentage,
                        color: finalColors[e.key % finalColors.length],
                        radius: 12,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: finalColors[e.key % finalColors.length], shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text(e.value.label, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyLarge?.color)),
                            ],
                          ),
                          Text("${e.value.percentage.toInt()}%", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopRoutesCard(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.topRoutes;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Top Routes", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          Text("This Month", style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          ...data.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.label, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 1,
                    child: Text(item.value.toInt().toString(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color), textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Banner ---
  Widget _buildRegisterBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface,
            theme.colorScheme.primary.withOpacity(0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Register your Company", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                Text("Unlock all features &\ngrow your transport business", style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.put(TransporterCompanyController());
                      Get.to(() => const TransporterCompanyForm());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Register Now", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          Image.asset(
            'assets/images/truck.png',
            height: 90,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // --- Quick Actions ---
  Widget _buildQuickActions(BuildContext context) {
    final allItems = [
      {'title': 'Branch', 'icon': IconlyLight.location, 'route': AppRoutes.transporterBranch},
      {'title': 'Brands', 'icon': IconlyLight.star, 'route': AppRoutes.transporterBrands},
      {'title': 'Category', 'icon': IconlyLight.category, 'route': AppRoutes.transporterCategory},
      {'title': 'Company', 'icon': IconlyLight.work, 'route': AppRoutes.transporterCompany},
      {'title': 'KYC', 'icon': IconlyLight.document, 'route': AppRoutes.transporterKyc},
      {'title': 'Contracts', 'icon': IconlyLight.paper, 'route': AppRoutes.transporterContracts},
      {'title': 'Notifications', 'icon': IconlyLight.notification, 'route': AppRoutes.transporterNotifications},
      {'title': 'Offers', 'icon': IconlyLight.ticket_star, 'route': AppRoutes.transporterOffers},
      {'title': 'Products', 'icon': IconlyLight.bag, 'route': AppRoutes.transporterProducts},
      {'title': 'RFQ', 'icon': IconlyLight.chat, 'route': AppRoutes.transporterRfq},
      {'title': 'Users', 'icon': IconlyLight.user_1, 'route': AppRoutes.transporterUsers},
    ];

    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 11) {
          return GlassCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz, size: 24, color: theme.colorScheme.primary),
                const SizedBox(height: 6),
                Text("More", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
              ],
            ),
          );
        }
        
        final item = allItems[index];
        return GestureDetector(
          onTap: () => Get.toNamed(item['route'] as String),
          child: GlassCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'] as IconData, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(item['title'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Performance Insights ---
  Widget _buildPerformanceInsights(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildPerformanceCard(context, controller.avgDeliveryTime.value),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, controller.onTimeDelivery.value),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, controller.fuelEfficiency.value),
          const SizedBox(width: 12),
          _buildPerformanceCard(context, controller.customerRating.value),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, MetricCard metric) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metric.title, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 4),
            Text(metric.value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(metric.isPositive ? IconlyBold.arrow_up : IconlyBold.arrow_down, size: 8, color: Colors.green),
                const SizedBox(width: 4),
                Text(metric.change, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Monthly Revenue Chart ---
  Widget _buildMonthlyRevenueChart(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.monthlyRevenue.value;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 50,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem("₹ 18,60,000", const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
                }
              )
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() < data.labels.length) {
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
                  interval: 10,
                  getTitlesWidget: (value, meta) {
                    return Text("${value.toInt()}L", style: TextStyle(fontSize: 8, color: theme.textTheme.bodyMedium?.color));
                  }
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: theme.dividerColor.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4])),
            borderData: FlBorderData(show: false),
            barGroups: data.values.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: theme.colorScheme.primary,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // --- Recent Activity ---
  Widget _buildRecentActivity(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = controller.activities[index];
        final theme = Theme.of(context);
        
        IconData icon;
        Color badgeColor;
        
        switch (activity.type) {
          case 'trip': icon = IconlyLight.location; badgeColor = Colors.green; break;
          case 'driver': icon = IconlyLight.user_1; badgeColor = Colors.blue; break;
          case 'branch': icon = IconlyLight.document; badgeColor = Colors.green; break;
          default: icon = IconlyLight.notification; badgeColor = Colors.orange;
        }
        
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
                child: Icon(icon, color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text(activity.subtitle, style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(activity.time, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      border: Border.all(color: badgeColor.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(activity.status, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: badgeColor)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
