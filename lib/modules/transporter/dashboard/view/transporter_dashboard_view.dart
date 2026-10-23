import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controller/transporter_dashboard_controller.dart';
import '../../company/view/transporter_company_form.dart';
import '../../company/controller/transporter_company_controller.dart';
import '../../bidding/view/transporter_bidding_view.dart';
import '../../../../services/notification_services.dart';
import '../../../../theme/glass_widgets.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/app_shell.dart';

/// Mirrors the web transporter dashboard: KPIs, trend, delivery status and routes.
/// The web menu items (shipment offers, my deals, drivers, vehicles, company,
/// branches) live in the side drawer, like the buyer and admin panels.
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
              _buildTransportTypesCard(context),
              const SizedBox(height: 16),
              _buildTopRoutesCard(context),
              const SizedBox(height: 16),
              _buildSlaDriversCard(context),
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
      leading: Builder(
        builder: (ctx) => IconButton(
          tooltip: 'Open navigation menu',
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
        StatefulBuilder(
          builder: (context, setState) => FutureBuilder<int>(
            future: NotificationServices.getUnreadCount(
              silent: true,
            ).catchError((_) => 0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(IconlyBold.home, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                controller.branchCodes.isEmpty
                    ? 'No branch assigned'
                    : 'Branch Code: ${controller.branchCodes.join(' - ')}',
                softWrap: true,
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
        // Same targets as the web dashboard KPIs (My Contract Bids page).
        () => Get.to(
          () =>
              const TransporterBiddingView(myBidsOnly: true, initialStatus: 'all'),
        ),
      ),
      (
        "Active Shipments",
        v('active', '0'),
        "Pickup due: ${v('pickupDue', '0')}",
        IconlyLight.bag,
        () => Get.to(
          () => const TransporterBiddingView(
            myBidsOnly: true,
            initialStatus: 'accepted',
          ),
        ),
      ),
      (
        "Delivered (MTD)",
        v('delivered', '0'),
        "On-time: ${v('onTime')}",
        IconlyLight.tick_square,
        () => Get.to(
          () =>
              const TransporterBiddingView(myBidsOnly: true, initialStatus: 'all'),
        ),
      ),
      (
        "In Transit",
        v('inTransit', '0'),
        "Avg ETA: ${v('avgETA')}",
        Icons.local_shipping_outlined,
        () => Get.to(
          () =>
              const TransporterBiddingView(myBidsOnly: true, initialStatus: 'all'),
        ),
      ),
      (
        "Delayed / Exceptions",
        v('delayed', '0'),
        "Incidents: ${v('incidents', '0')}",
        IconlyLight.danger,
        () => Get.to(
          () =>
              const TransporterBiddingView(myBidsOnly: true, initialStatus: 'all'),
        ),
      ),
      (
        "Cost per KM",
        v('costKm'),
        "Fuel variance: ${v('fuelVar')}",
        Icons.local_gas_station_outlined,
        () => Get.to(() => const TransporterBiddingView(myBidsOnly: true)),
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
        () => Get.to(() => const TransporterBiddingView(myBidsOnly: true)),
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
          // An all-zero period still shows the chart (zero line, 0-1.0 axes) like the web;
          // the message is only for a period with no buckets at all.
          if (earnings.labels.isEmpty && shipments.labels.isEmpty)
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

  static ({double max, double interval, int decimals}) _calculateScale(
    double maxRaw,
    int divisions, {
    bool isInteger = false,
    double fallbackMax = 1.0,
  }) {
    if (maxRaw <= 0) {
      // Empty period: 0, 0.2 ... 1.0 on both axes, as on the web chart.
      return (max: 1.0, interval: 0.2, decimals: 1);
    }

    if (isInteger) {
      // Clean integer shipment scales matching web panel
      if (maxRaw <= 2.0) {
        return (max: 2.0, interval: 0.4, decimals: 1);
      } else if (maxRaw <= 5.0) {
        return (max: 5.0, interval: 1.0, decimals: 0);
      } else if (maxRaw <= 10.0) {
        return (max: 10.0, interval: 2.0, decimals: 0);
      }
    }

    final rawInterval = maxRaw / divisions;
    final exponent = (log(rawInterval) / ln10).floor();
    final fraction = rawInterval / pow(10, exponent);

    double niceFraction;
    if (fraction <= 1.0) {
      niceFraction = 1.0;
    } else if (fraction <= 2.0) {
      niceFraction = 2.0;
    } else if (fraction <= 2.5) {
      niceFraction = 2.5;
    } else if (fraction <= 4.0) {
      niceFraction = 4.0;
    } else if (fraction <= 5.0) {
      niceFraction = 5.0;
    } else {
      niceFraction = 10.0;
    }

    var interval = double.parse(
      (niceFraction * pow(10, exponent)).toStringAsFixed(4),
    );
    var max = double.parse(
      ((maxRaw / interval).ceil() * interval).toStringAsFixed(4),
    );
    while (max < maxRaw) {
      max = double.parse((max + interval).toStringAsFixed(4));
    }

    int decimals = 0;
    if (interval < 1.0) {
      if ((interval * 10).roundToDouble() == (interval * 10)) {
        decimals = 1;
      } else if ((interval * 100).roundToDouble() == (interval * 100)) {
        decimals = 2;
      } else {
        decimals = 3;
      }
    }

    return (max: max, interval: interval, decimals: decimals);
  }

  Widget _buildCombinedChart(
    BuildContext context,
    ChartSeries earnings,
    ChartSeries shipments,
  ) {
    final theme = Theme.of(context);
    final labels = earnings.labels.isNotEmpty
        ? earnings.labels
        : shipments.labels;
    final int count = labels.length;

    // Use 6 intervals matching the Web Transporter Dashboard grid
    const int divisions = 6;

    final maxEarnRaw = earnings.values.isEmpty
        ? 0.0
        : earnings.values.reduce((a, b) => a > b ? a : b);
    final earnScale = _calculateScale(maxEarnRaw, divisions, fallbackMax: 0.12);

    final maxShipRaw = shipments.values.isEmpty
        ? 0.0
        : shipments.values.reduce((a, b) => a > b ? a : b);
    final shipScale = _calculateScale(
      maxShipRaw,
      divisions,
      isInteger: true,
      fallbackMax: 2.0,
    );

    final double barWidth = count <= 3
        ? 42.0
        : (count <= 7 ? 22.0 : (count <= 12 ? 14.0 : 8.0));

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
                  // Bar centres at (i + 0.5) / count, matching the line's x range below.
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  maxY: shipScale.max,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: shipScale.interval,
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
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize:
                            46, // Reserved for Earnings scale on the left
                        getTitlesWidget: _emptyTitleWidget,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: shipScale.interval,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > shipScale.max + 0.001) {
                            return const SizedBox.shrink();
                          }
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
                            toY: i < shipments.values.length
                                ? shipments.values[i]
                                : 0.0,
                            color: _gold.withValues(alpha: 0.85),
                            width: barWidth,
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
                  // -0.5 .. count-0.5 puts each point over its bar (it used to run
                  // edge to edge, so points and bars did not line up).
                  minX: -0.5,
                  maxX: count - 0.5,
                  minY: 0,
                  maxY: earnScale.max,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize:
                            36, // Reserve same width as Right Axis to match coordinates
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
                        interval: earnScale.interval,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > earnScale.max + 0.0001) {
                            return const SizedBox.shrink();
                          }
                          final formatted = value == 0
                              ? "0"
                              : value.toStringAsFixed(earnScale.decimals);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              formatted,
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
                            i < earnings.values.length
                                ? earnings.values[i]
                                : 0.0,
                          ),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.25,
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 0.0,
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

  Widget _buildTransportTypesCard(BuildContext context) {
    final theme = Theme.of(context);
    final series = controller.transportTypes.value;
    final totalVehicles = series.values.fold<double>(0, (a, b) => a + b);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  IconlyLight.discovery,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Transport Types",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (series.labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No vehicle fleet data yet",
                  style: TextStyle(color: theme.disabledColor, fontSize: 12),
                ),
              ),
            )
          else ...[
            for (var i = 0; i < series.labels.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        series.labels[i].capitalizeFirst ?? series.labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${series.values.length > i ? series.values[i].toInt() : 0} vehicles",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalVehicles > 0 && series.values.length > i
                          ? (series.values[i] / totalVehicles).clamp(0.0, 1.0)
                          : 1.0,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor.withValues(
                        alpha: 0.15,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTopRoutesCard(BuildContext context) {
    final theme = Theme.of(context);
    final series = controller.topRoutes.value;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  IconlyLight.location,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Top Routes (Trips)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (series.labels.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No route trips completed yet",
                  style: TextStyle(color: theme.disabledColor, fontSize: 12),
                ),
              ),
            )
          else ...[
            for (var i = 0; i < series.labels.length; i++) ...[
              if (i > 0) const Divider(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 18,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      series.labels[i],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${series.values.length > i ? series.values[i].toInt() : 0} trips",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSlaDriversCard(BuildContext context) {
    final theme = Theme.of(context);
    final series = controller.slaDrivers.value;
    final k = controller.kpis;
    final onTimeKpi = k['onTime']?.toString().trim() ?? '';
    final hasDriverList = series.labels.isNotEmpty;
    final hasKpi =
        onTimeKpi.isNotEmpty && onTimeKpi != '—' && onTimeKpi != 'Not tracked';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "SLA: On-time % (Drivers)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Target: 90%",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDriverList) ...[
            for (var i = 0; i < series.labels.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final otd = series.values.length > i ? series.values[i] : 0.0;
                  final progress = (otd / 100.0).clamp(0.0, 1.0);
                  final slaColor = otd >= 90
                      ? const Color(0xFF10B981)
                      : (otd >= 70 ? Colors.orange : Colors.redAccent);
                  return Column(
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
                              Text(
                                series.labels[i],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                              color: slaColor.withValues(alpha: 0.12),
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
                          backgroundColor: theme.dividerColor.withValues(
                            alpha: 0.15,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(slaColor),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ] else if (hasKpi) ...[
            Builder(
              builder: (context) {
                final numericStr = onTimeKpi.replaceAll(RegExp(r'[^0-9.]'), '');
                final double otd = double.tryParse(numericStr) ?? 100.0;
                final progress = (otd / 100.0).clamp(0.0, 1.0);
                final slaColor = otd >= 90
                    ? const Color(0xFF10B981)
                    : (otd >= 70 ? Colors.orange : Colors.redAccent);
                return Column(
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
                            Text(
                              "Fleet On-Time Performance",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                            color: slaColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            onTimeKpi.contains('%')
                                ? onTimeKpi
                                : "$onTimeKpi% On-Time",
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
                        backgroundColor: theme.dividerColor.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(slaColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "SLA target met • Deliveries running on schedule",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  "No driver SLA recorded yet",
                  style: TextStyle(color: theme.disabledColor, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
