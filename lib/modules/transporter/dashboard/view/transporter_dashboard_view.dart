import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controller/transporter_dashboard_controller.dart';
import '../../company/view/transporter_company_form.dart';
import '../../company/controller/transporter_company_controller.dart';
import '../../bidding/view/transporter_bidding_view.dart';
import '../../../seller/branches/view/seller_branches_view.dart';
import '../../../../services/notification_services.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../routes/app_routes.dart';

/// Mirrors the web transporter dashboard: KPIs, trend, delivery status, routes, and the
/// web menu items (company, drivers, vehicles, branches, shipment offers, my deals).
class TransporterDashboardView extends StatelessWidget {
  TransporterDashboardView({super.key});

  final TransporterDashboardController controller = Get.put(TransporterDashboardController());
  final TransporterCompanyController companyController = Get.put(TransporterCompanyController());

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value && controller.kpis.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _gold));
        }
        return RefreshIndicator(
          color: _gold,
          onRefresh: () async {
            await controller.fetchDashboardOverview();
            await companyController.fetchCompanies();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _buildHero(context),
              if (controller.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)),
              ],
              if (!companyController.isLoading.value && companyController.companies.isEmpty) ...[
                const SizedBox(height: 16),
                _buildRegisterBanner(context),
              ],
              const SizedBox(height: 20),
              _sectionTitle(context, "Quick Actions"),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _sectionTitle(context, "Overview"),
              const SizedBox(height: 12),
              _buildKpiGrid(context),
              const SizedBox(height: 24),
              _buildTrendCard(context),
              const SizedBox(height: 16),
              _buildDeliveryStatusCard(context),
              const SizedBox(height: 16),
              _buildListCard(context, "Transport Types", controller.transportTypes.value, IconlyLight.discovery, "vehicles"),
              const SizedBox(height: 16),
              _buildListCard(context, "Top Routes", controller.topRoutes.value, IconlyLight.location, "trips"),
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Image.asset('assets/images/app_name.png', height: 32, fit: BoxFit.contain),
      centerTitle: true,
      actions: [
        StatefulBuilder(
          builder: (context, setState) => FutureBuilder<int>(
            future: NotificationServices.getUnreadCount().catchError((_) => 0),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(IconlyLight.notification),
                    onPressed: () async {
                      await Get.toNamed(AppRoutes.transporterNotifications);
                      setState(() {});
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                        child: Text(unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateText = "${days[now.weekday - 1]}, ${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}";
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Transporter Dashboard",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text(
            "Welcome, ${controller.username.value.isEmpty ? 'Transporter' : controller.username.value}! "
            "Track shipments, earnings & fleet utilization.",
            style: GoogleFonts.inter(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
          ),
          if (controller.branchCodes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("Branch Code: ${controller.branchCodes.join(' - ')}",
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 6),
          Text(dateText, style: GoogleFonts.inter(fontSize: 11, color: _gold, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRegisterBanner(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(IconlyBold.work, color: _gold, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Register your Company",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                Text("Needed before you can bid on shipments.",
                    style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.to(() => const TransporterCompanyForm())?.then((_) => companyController.fetchCompanies()),
            style: ElevatedButton.styleFrom(backgroundColor: _gold),
            child: const Text("Register", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color));
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <(String, IconData, VoidCallback)>[
      ("Shipment Offers", IconlyLight.ticket_star, () => Get.to(() => const TransporterBiddingView())),
      ("My Deals", IconlyLight.document, () => Get.to(() => const TransporterBiddingView(initialTab: 1))),
      ("Company", IconlyLight.work, () => Get.toNamed(AppRoutes.transporterCompany)),
      ("Drivers", IconlyLight.user_1, () => Get.toNamed(AppRoutes.transporterDrivers)),
      ("Vehicles", IconlyLight.discovery, () => Get.toNamed(AppRoutes.transporterVehicles)),
      ("My Branches", IconlyLight.location, () => Get.to(() => const SellerBranchesView())),
      ("Notifications", IconlyLight.notification, () => Get.toNamed(AppRoutes.transporterNotifications)),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: actions
          .map((a) => InkWell(
                onTap: a.$3,
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                      child: Icon(a.$2, color: _gold, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(a.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    final k = controller.kpis;
    String v(String key, [String fallback = '—']) => k[key] == null ? fallback : '${k[key]}';
    final cards = <(String, String, String, IconData)>[
      ("Earnings (MTD)", v('earn', '₹0.00'), v('earnDelta', ''), Icons.currency_rupee),
      ("Active Shipments", v('active', '0'), "Pickup due: ${v('pickupDue', '0')}", IconlyLight.bag),
      ("Delivered (MTD)", v('delivered', '0'), "On-time: ${v('onTime')}", IconlyLight.tick_square),
      ("In Transit", v('inTransit', '0'), "Avg ETA: ${v('avgETA')}", Icons.local_shipping_outlined),
      ("Delayed / Exceptions", v('delayed', '0'), "Incidents: ${v('incidents', '0')}", IconlyLight.danger),
      ("Cost per KM", v('costKm'), "Fuel variance: ${v('fuelVar')}", Icons.local_gas_station_outlined),
      ("Fleet Utilization", v('util', '0%'), "Active vehicles: ${v('vehicles', '0')}", IconlyLight.chart),
      ("Avg Delivery Time", v('avgTime'), "SLA breach rate: ${v('breach')}", IconlyLight.time_circle),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: cards.map((c) => _kpiCard(context, c.$1, c.$2, c.$3, c.$4)).toList(),
    );
  }

  Widget _kpiCard(BuildContext context, String title, String value, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.deepOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.deepOrange),
          ),
          const Spacer(),
          Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          ),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context) {
    final theme = Theme.of(context);
    final range = controller.currentRange;
    final earnings = range['earnings'] ?? const ChartSeries([], []);
    final shipments = range['shipments'] ?? const ChartSeries([], []);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text("Earnings & Shipments Trend", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: ['7D', '1M', '3M', '1Y']
                .map((key) => ChoiceChip(
                      label: Text(key),
                      selected: controller.selectedRange.value == key,
                      selectedColor: _gold,
                      onSelected: (_) => controller.selectedRange.value = key,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          if (earnings.isEmpty && shipments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text("No accepted shipments in this period", style: TextStyle(color: theme.disabledColor))),
            )
          else ...[
            Text("Shipments", style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
            SizedBox(height: 140, child: _barChart(context, shipments, _gold)),
            const SizedBox(height: 12),
            Text("Earnings (₹ Lakhs)", style: GoogleFonts.inter(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
            SizedBox(height: 140, child: _lineChart(context, earnings, Colors.deepOrange)),
          ],
        ],
      ),
    );
  }

  FlTitlesData _titles(BuildContext context, List<String> labels) {
    final style = TextStyle(fontSize: 9, color: Theme.of(context).textTheme.bodyMedium?.color);
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) => Text(value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1), style: style),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= labels.length || value != i.toDouble()) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: style));
          },
        ),
      ),
    );
  }

  Widget _barChart(BuildContext context, ChartSeries series, Color color) {
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: _titles(context, series.labels),
      barGroups: [
        for (var i = 0; i < series.values.length; i++)
          BarChartGroupData(x: i, barRods: [BarChartRodData(toY: series.values[i], color: color, width: 12, borderRadius: BorderRadius.circular(4))]),
      ],
    ));
  }

  Widget _lineChart(BuildContext context, ChartSeries series, Color color) {
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: _titles(context, series.labels),
      minY: 0,
      lineBarsData: [
        LineChartBarData(
          spots: [for (var i = 0; i < series.values.length; i++) FlSpot(i.toDouble(), series.values[i])],
          isCurved: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    ));
  }

  Widget _buildDeliveryStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final status = controller.deliveryStatus.value;
    const colors = [Colors.green, Color(0xFFFFC107), Colors.blue, Colors.red];
    final total = status.values.fold<double>(0, (a, b) => a + b);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Delivery Status", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text("No deliveries yet", style: TextStyle(color: theme.disabledColor))),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: PieChart(PieChartData(
                    centerSpaceRadius: 34,
                    sectionsSpace: 2,
                    sections: [
                      for (var i = 0; i < status.values.length; i++)
                        if (status.values[i] > 0)
                          PieChartSectionData(value: status.values[i], color: colors[i % colors.length], title: '', radius: 26),
                    ],
                  )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < status.labels.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(status.labels[i], style: const TextStyle(fontSize: 12))),
                              Text(status.values.length > i ? status.values[i].toInt().toString() : '0',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context, String title, ChartSeries series, IconData icon, String unit) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          if (series.labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text("No data yet", style: TextStyle(color: theme.disabledColor)),
            ),
          for (var i = 0; i < series.labels.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: _gold, size: 18),
              title: Text(series.labels[i], style: const TextStyle(fontSize: 13)),
              trailing: Text("${series.values.length > i ? series.values[i].toInt() : 0} $unit",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
