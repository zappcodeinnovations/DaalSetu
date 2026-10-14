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

  final TransporterDashboardController controller = Get.put(
    TransporterDashboardController(),
  );
  final TransporterCompanyController companyController = Get.put(
    TransporterCompanyController(),
  );

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (!companyController.isLoading.value &&
                  companyController.companies.isEmpty) ...[
                const SizedBox(height: 16),
                _buildRegisterBanner(context),
              ],
              const SizedBox(height: 20),
              _sectionTitle(context, "Transporter Workspace"),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 15),
              _sectionTitle(context, "Overview KPIs"),
              const SizedBox(height: 12),
              _buildKpiGrid(context),
              const SizedBox(height: 24),
              _sectionTitle(context, "Analytics Overview"),
              const SizedBox(height: 12),
              _buildTrendCard(context),
              const SizedBox(height: 16),
              _buildDeliveryStatusCard(context),
              const SizedBox(height: 16),
              _buildListCard(
                context,
                "Transport Types",
                controller.transportTypes.value,
                IconlyLight.discovery,
                "vehicles",
              ),
              const SizedBox(height: 16),
              _buildListCard(
                context,
                "Top Routes",
                controller.topRoutes.value,
                IconlyLight.location,
                "trips",
              ),
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
      title: Image.asset(
        'assets/images/app_name.png',
        height: 32,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        StatefulBuilder(
          builder: (context, setState) => FutureBuilder<int>(
            future: NotificationServices.getUnreadCount(silent: true).catchError((_) => 0),
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
                        decoration: const BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.profile_page),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
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

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final name = controller.username.value.isEmpty
        ? 'Transporter'
        : controller.username.value;
    final kyc = controller.kycStatus.value.trim();
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
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const Text(" 👋", style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(IconlyBold.home, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                controller.branchCodes.isEmpty
                    ? 'No branch assigned'
                    : controller.branchCodes.join(' - '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (kyc.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "KYC: ${kyc.toUpperCase()}",
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
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
                Text(
                  "Register your Company",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  "Needed before you can bid on shipments.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.to(
              () => const TransporterCompanyForm(),
            )?.then((_) => companyController.fetchCompanies()),
            style: ElevatedButton.styleFrom(backgroundColor: _gold),
            child: const Text(
              "Register",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final actions = <(String, String, IconData, Color, VoidCallback)>[
      (
        "Shipment Offers",
        "Browse active loads",
        IconlyBold.ticket_star,
        Colors.orange,
        () => Get.to(() => const TransporterBiddingView()),
      ),
      (
        "My Deals",
        "Track accepted shipments",
        IconlyBold.document,
        Colors.teal,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1)),
      ),
      (
        "Company",
        "Registration & profile",
        IconlyBold.work,
        Colors.blueGrey,
        () => Get.toNamed(AppRoutes.transporterCompany),
      ),
      (
        "Drivers",
        "Manage registered drivers",
        IconlyBold.user_3,
        Colors.indigo,
        () => Get.toNamed(AppRoutes.transporterDrivers),
      ),
      (
        "Vehicles",
        "Manage registered fleet",
        IconlyBold.discovery,
        Colors.deepOrange,
        () => Get.toNamed(AppRoutes.transporterVehicles),
      ),
      (
        "My Branches",
        "View assigned branches",
        IconlyBold.location,
        Colors.green,
        () => Get.to(() => const SellerBranchesView()),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: actions
          .map(
            (a) => GlassCard(
              onTap: a.$5,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: a.$4.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(a.$3, color: a.$4, size: 20),
                      ),
                      Icon(IconlyLight.arrow_right_2, color: a.$4, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    a.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    a.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    final k = controller.kpis;
    String v(String key, [String fallback = '—']) =>
        k[key] == null ? fallback : '${k[key]}';
    final cards = <(String, String, String, IconData, VoidCallback?)>[
      (
        "Earnings (MTD)",
        v('earn', '₹0.00'),
        v('earnDelta', ''),
        Icons.currency_rupee,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1, initialStatus: 'accepted')),
      ),
      (
        "Active Shipments",
        v('active', '0'),
        "Pickup due: ${v('pickupDue', '0')}",
        IconlyLight.bag,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1, initialStatus: 'accepted')),
      ),
      (
        "Delivered (MTD)",
        v('delivered', '0'),
        "On-time: ${v('onTime')}",
        IconlyLight.tick_square,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1, initialStatus: 'all')),
      ),
      (
        "In Transit",
        v('inTransit', '0'),
        "Avg ETA: ${v('avgETA')}",
        Icons.local_shipping_outlined,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1, initialStatus: 'accepted')),
      ),
      (
        "Delayed / Exceptions",
        v('delayed', '0'),
        "Incidents: ${v('incidents', '0')}",
        IconlyLight.danger,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1, initialStatus: 'all')),
      ),
      (
        "Cost per KM",
        v('costKm'),
        "Fuel variance: ${v('fuelVar')}",
        Icons.local_gas_station_outlined,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1)),
      ),
      (
        "Fleet Utilization",
        v('util', '0%'),
        "Active vehicles: ${v('vehicles', '0')}",
        IconlyLight.chart,
        () => Get.toNamed(AppRoutes.transporterVehicles),
      ),
      (
        "Avg Delivery Time",
        v('avgTime'),
        "SLA breach rate: ${v('breach')}",
        IconlyLight.time_circle,
        () => Get.to(() => const TransporterBiddingView(initialTab: 1)),
      ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: cards
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 145,
                  height: 132,
                  child: _kpiCard(context, c.$1, c.$2, c.$3, c.$4, onTap: c.$5),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.deepOrange),
          ),
          const Spacer(),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
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
              Expanded(
                child: Text(
                  "Earnings & Shipments Trend",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: ['7D', '1M', '3M', '1Y']
                .map(
                  (key) => ChoiceChip(
                    label: Text(key),
                    selected: controller.selectedRange.value == key,
                    selectedColor: _gold,
                    onSelected: (_) => controller.selectedRange.value = key,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          if (earnings.isEmpty && shipments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  "No accepted shipments in this period",
                  style: TextStyle(color: theme.disabledColor),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            // Legends matching the web application
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.deepOrange, width: 2.5),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Earnings (₹ Lakhs)",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Shipments",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Combined Chart with Dual Axis (Left: Earnings, Right: Shipments)
            SizedBox(
              height: 220,
              child: _buildCombinedChart(context, earnings, shipments),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedChart(
    BuildContext context,
    ChartSeries earnings,
    ChartSeries shipments,
  ) {
    final theme = Theme.of(context);
    final labels = earnings.labels.isNotEmpty ? earnings.labels : shipments.labels;
    final int count = labels.length;

    // Calculate maximum values for clean dual-axis scaling
    final maxEarnRaw = earnings.values.isEmpty
        ? 0.05
        : earnings.values.reduce((a, b) => a > b ? a : b);
    final double maxEarn = maxEarnRaw > 0 ? (maxEarnRaw * 1.25) : 0.05;

    final maxShipRaw = shipments.values.isEmpty
        ? 1.0
        : shipments.values.reduce((a, b) => a > b ? a : b);
    final double maxShip = maxShipRaw > 0 ? (maxShipRaw * 1.25).ceilToDouble() : 1.0;

    final axisTextStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: theme.textTheme.bodySmall?.color ?? Colors.grey.shade600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Layer 1: Background grid, Bottom X-Axis labels, and Right Axis (Shipments)
            Positioned.fill(
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxShip,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxShip / 4 > 0 ? maxShip / 4 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      left: BorderSide.none,
                      right: BorderSide.none,
                      top: BorderSide.none,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46, // Reserved for Earnings scale on the left
                        getTitlesWidget: _emptyTitleWidget,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value < 0) return const SizedBox.shrink();
                          final formatted = value == value.roundToDouble()
                              ? value.toInt().toString()
                              : value.toStringAsFixed(1);
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(formatted, style: axisTextStyle),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= count || value != i.toDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[i], style: axisTextStyle),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < count; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: i < shipments.values.length ? shipments.values[i] : 0.0,
                            color: _gold.withValues(alpha: 0.75),
                            width: 32,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Layer 2: Foreground Smooth Curved Line (Earnings in ₹ Lakhs) with Left Axis
            Positioned.fill(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxEarn,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36, // Reserve same width as Right Axis to match coordinates
                        getTitlesWidget: _emptyTitleWidget,
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26, // Reserve same width as Bottom Axis
                        getTitlesWidget: _emptyTitleWidget,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (value, meta) {
                          if (value < 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              value == 0 ? "0" : value.toStringAsFixed(3),
                              textAlign: TextAlign.right,
                              style: axisTextStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < count; i++)
                          FlSpot(
                            i.toDouble(),
                            i < earnings.values.length ? earnings.values[i] : 0.0,
                          ),
                      ],
                      isCurved: true,
                      color: Colors.deepOrange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.deepOrange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepOrange.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _emptyTitleWidget(double value, TitleMeta meta) {
    return const SizedBox.shrink();
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
          Text(
            "Delivery Status",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No deliveries yet",
                  style: TextStyle(color: theme.disabledColor),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 34,
                      sectionsSpace: 2,
                      sections: [
                        for (var i = 0; i < status.values.length; i++)
                          if (status.values[i] > 0)
                            PieChartSectionData(
                              value: status.values[i],
                              color: colors[i % colors.length],
                              title: '',
                              radius: 26,
                            ),
                      ],
                    ),
                  ),
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
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  status.labels[i],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                status.values.length > i
                                    ? status.values[i].toInt().toString()
                                    : '0',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildListCard(
    BuildContext context,
    String title,
    ChartSeries series,
    IconData icon,
    String unit,
  ) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (series.labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No data yet",
                style: TextStyle(color: theme.disabledColor),
              ),
            ),
          for (var i = 0; i < series.labels.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: _gold, size: 18),
              title: Text(
                series.labels[i],
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Text(
                "${series.values.length > i ? series.values[i].toInt() : 0} $unit",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
