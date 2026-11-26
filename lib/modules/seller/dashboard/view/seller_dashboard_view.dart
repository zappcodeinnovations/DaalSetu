import 'package:daalsetu/widgets/dashboard_period_bar.dart';
import '../../challans/view/seller_delivery_challan_view.dart';
import 'package:flutter/material.dart';
import 'package:daalsetu/widgets/header_profile_avatar.dart';
import 'package:daalsetu/widgets/app_shell.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controller/seller_dashboard_controller.dart';
import '../model/seller_dashboard_model.dart';
import '../../../../theme/glass_widgets.dart';
import '../../products/view/seller_product_view.dart';
import '../../contracts/view/seller_contracts_view.dart';
import '../../buyer_offers/view/seller_buyer_offers_view.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import '../../products/controller/seller_product_controller.dart';
import '../../products/view/add_product_view.dart';
import '../../../../services/notification_services.dart';
import '../../../../routes/app_routes.dart';

class SellerDashboardView extends StatelessWidget {
  SellerDashboardView({super.key});

  final SellerDashboardController controller = Get.put(
    SellerDashboardController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isError.value) {
          return Center(
            child: Text(
              "Error: ${controller.errorMessage.value}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final data = controller.dashboardData.value;
        if (data == null) return const Center(child: Text("No Data Found"));

        return RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context, data.header),
                DashboardPeriodBar(onChanged: controller.fetchDashboardData),
                const SizedBox(height: 2),
                _buildSectionHeader(
                  context,
                  "Overview KPIs",
                  trailingText: "View All",
                  onTrailingTap: () => _showKpiDetails(context, data.kpis),
                ),
                const SizedBox(height: 12),
                _buildTodaysOverview(context, data.kpis),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Analytics Overview",
                  trailingText: "View All",
                  onTrailingTap: () =>
                      _showAnalyticsDetails(context, data.charts),
                ),
                const SizedBox(height: 16),
                _buildAnalyticsGrid(context, data.charts),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Recent Deals",
                  trailingText: "View All",
                  onTrailingTap: () =>
                      Get.to(() => const SellerBuyerOffersView()),
                ),
                const SizedBox(height: 16),
                _buildRecentDeals(context, data.recentDeals),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Recent Contracts",
                  trailingText: "View All",
                  onTrailingTap: () =>
                      Get.to(() => const SellerContractsView()),
                ),
                const SizedBox(height: 16),
                _buildRecentContracts(context, data.recentContracts),

                const SizedBox(height: 100), // Bottom nav padding
              ],
            ),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return HeroHeader(
      leading: const AppBarLeading(showBack: false),
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
          StatefulBuilder(
            builder: (context, setState) => FutureBuilder<int>(
              future: NotificationServices.getUnreadCount(silent: true).catchError((_) => 0),
              builder: (context, snapshot) {
                final unread = snapshot.data ?? 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(IconlyLight.notification, color: Colors.white, size: 24),
                      onPressed: () async {
                        await Get.toNamed(AppRoutes.sellerNotifications);
                        setState(() {});
                      },
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
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
          const SizedBox(width: 4),
          const HeaderProfileAvatar(),
        ],
      ),
      bottom: Obx(() {
        final data = controller.dashboardData.value;
        final sellerName = data?.header.name.trim() ?? '';
        final branch = data?.header.branchName.trim() ?? '';
        final kyc = (data?.header.kycStatus ?? '').trim().toUpperCase();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sellerName.isNotEmpty ? "Hello, $sellerName 👋" : "Seller Dashboard",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              branch.isNotEmpty && kyc.isNotEmpty
                  ? "$branch • KYC: $kyc"
                  : "Welcome back to your trading desk",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeroSection(BuildContext context, SellerHeader header) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Trading Desk Active",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Post commodity offers, respond to RFQs & manage mill contracts.",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () {
              if (!Get.isRegistered<SellerProductController>()) {
                Get.put(SellerProductController());
              }
              Get.to(() => const AddProductView());
            },
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text("Post Offer", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? trailingText,
    Widget? trailing,
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
          TextButton(
            onPressed: onTrailingTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              trailingText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          )
        else if (trailing != null)
          trailing,
      ],
    );
  }

  IconData _getKpiIcon(SellerKpi kpi) {
    final titleLower = kpi.title.toLowerCase();
    final screenLower = kpi.screen.toLowerCase();

    if (kpi.type == 'currency' || titleLower.contains('earning') || titleLower.contains('revenue')) {
      return IconlyLight.wallet;
    }
    if (screenLower == 'buyer_offers' || titleLower.contains('deal') || titleLower.contains('negotiat')) {
      return IconlyLight.swap;
    }
    if (screenLower == 'contracts' || titleLower.contains('contract')) {
      return IconlyLight.document;
    }
    if (screenLower == 'offers' || titleLower.contains('listing') || titleLower.contains('product')) {
      return Icons.inventory_2_outlined;
    }
    if (screenLower == 'challans' || titleLower.contains('transit') || titleLower.contains('shipment')) {
      return Icons.local_shipping_outlined;
    }
    return IconlyLight.chart;
  }

  Widget _buildTodaysOverview(BuildContext context, List<SellerKpi> kpis) {
    if (kpis.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        final hasFeaturedFirst = kpis.length.isOdd && kpis.length > 1;

        if (hasFeaturedFirst) {
          final firstKpi = kpis.first;
          final remainingKpis = kpis.skip(1).toList();

          return Column(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                child: _buildDynamicMetricCard(
                  context,
                  firstKpi,
                  _getKpiIcon(firstKpi),
                  isFullWidth: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: remainingKpis.map((kpi) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildDynamicMetricCard(
                      context,
                      kpi,
                      _getKpiIcon(kpi),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis.map((kpi) {
            return SizedBox(
              width: cardWidth,
              child: _buildDynamicMetricCard(
                context,
                kpi,
                _getKpiIcon(kpi),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDynamicMetricCard(
    BuildContext context,
    SellerKpi metric,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openKpi(metric.screen),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFFFE082).withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isFullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: const Color(0xFFE65100)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metric.type == 'currency'
                              ? "₹${metric.value}"
                              : metric.value.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (metric.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            metric.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: const Color(0xFFE65100)),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    metric.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.type == 'currency'
                        ? "₹${metric.value}"
                        : metric.value.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (metric.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      metric.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// A count as a clean whole number ("4"), whether the server sent 4, 4.0 or "4.0".
  @visibleForTesting
  static String countText(dynamic value) {
    final number = value is num ? value : num.tryParse('${value ?? ''}'.trim());
    if (number == null) return '${value ?? 0}';
    return number == number.roundToDouble() ? number.toInt().toString() : number.toString();
  }

  void _openKpi(String screen) {
    switch (screen) {
      case 'challans':
        // In Transit: the dispatched, not yet delivered shipments (the same ones the count shows).
        Get.to(() => const SellerDeliveryChallanView(statusFilter: 'dispatched'));
        return;
      case 'buyer_offers':
        Get.to(() => const SellerBuyerOffersView());
        return;
      case 'contracts':
        Get.to(() => const SellerContractsView());
        return;
      case 'offers':
        Get.to(() => const SellerProductView());
        return;
      default:
        return;
    }
  }

  void _showKpiDetails(BuildContext context, List<SellerKpi> kpis) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview KPIs',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: kpis.isEmpty
                    ? const Center(child: Text('No KPI data is available yet.'))
                    : ListView.separated(
                        itemCount: kpis.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final kpi = kpis[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(kpi.title),
                            subtitle: Text(kpi.subtitle),
                            trailing: Text(
                              kpi.type == 'currency'
                                  ? 'Rs ${kpi.value}'
                                  : '${kpi.value}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onTap: () {
                              Get.back();
                              _openKpi(kpi.screen);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAnalyticsDetails(BuildContext context, SellerCharts charts) {
    final pipeline = charts.dealPipeline;
    final commodities = charts.commodityMix;
    Get.bottomSheet(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            children: [
              Text(
                'Analytics Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Deal Pipeline',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              if (pipeline.isEmpty)
                const Text('No pipeline data is available yet.')
              else
                ...pipeline.entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key.replaceAll('_', ' ')),
                    trailing: Text(countText(entry.value)),
                  ),
                ),
              const Divider(height: 28),
              Text(
                'Commodity Mix',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              if (commodities.isEmpty)
                const Text('No commodity data is available yet.')
              else
                ...commodities.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.categoryName),
                    trailing: Text('${item.volume.toStringAsFixed(0)}%'),
                  ),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context, SellerCharts charts) {
    return Column(
      children: [
        _buildPipelineCard(context, charts.dealPipeline),
        const SizedBox(height: 12),
        _buildDonutCard(
          context,
          "Commodity Mix",
          "Overall",
          charts.commodityMix,
        ),
      ],
    );
  }

  Widget _buildPipelineCard(
    BuildContext context,
    Map<String, dynamic> pipeline,
  ) {
    final theme = Theme.of(context);

    final labels = pipeline.keys.toList();
    final values = pipeline.values
        .map((e) => double.tryParse('$e') ?? 0)
        .toList();
    final bool hasData = values.any((v) => v > 0);
    double maxY = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 10;
    if (maxY == 0) maxY = 10;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deal Pipeline",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    "By Stage",
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
              if (!hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "0 Active",
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasData)
            SizedBox(
              height: 112,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 16,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: List.generate(labels.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: values[index],
                          width: 8,
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(labels.length, (index) {
                  return Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE65100).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "0",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 60,
                        child: Text(
                          labels[index].replaceAll('_', ' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          if (hasData && labels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(
                          label.replaceAll('_', ' '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonutCard(
    BuildContext context,
    String title,
    String subtitle,
    List<CommodityMix> items,
  ) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
    ];

    if (items.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 8,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconlyLight.chart,
                      size: 26,
                      color: const Color(0xFFE65100).withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "No commodity volume data available yet",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color,
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

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 8,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
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
                        value: e.value.volume,
                        color: colors[e.key % colors.length],
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
                  children: items.take(4).toList().asMap().entries.map((e) {
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
                                    color: colors[e.key % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    e.value.categoryName,
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
                            "${e.value.volume.toInt()}%",
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
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

  Widget _buildEmptySectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: const Color(0xFFE65100)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE65100),
                side: const BorderSide(color: Color(0xFFE65100), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentDeals(BuildContext context, List<SellerDeal> deals) {
    if (deals.isEmpty) {
      return _buildEmptySectionCard(
        context: context,
        icon: IconlyLight.swap,
        title: "No recent deals",
        subtitle: "Deals will appear here once buyers confirm quotes.",
        actionLabel: "Post Offer",
        onAction: () {
          if (!Get.isRegistered<SellerProductController>()) {
            Get.put(SellerProductController());
          }
          Get.to(() => const AddProductView());
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deals.length > 5 ? 5 : deals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deal = deals[index];
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
                  IconlyLight.swap,
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
                      "${deal.categoryName} - ${deal.brandName}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${deal.requestedQuantity} Tons",
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
                    "₹${deal.requestedAmount}",
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
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      deal.status.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
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
    List<SellerContract> contracts,
  ) {
    if (contracts.isEmpty) {
      return _buildEmptySectionCard(
        context: context,
        icon: IconlyLight.document,
        title: "No recent contracts",
        subtitle: "Signed trade contracts will be listed here.",
      );
    }

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
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyLight.document,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.buyerCompany.trim().isNotEmpty
                          ? contract.buyerCompany.trim()
                          : contract.buyerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (contract.categoryName.trim().isNotEmpty)
                          contract.categoryName.trim(),
                        if (contract.brandName.trim().isNotEmpty)
                          contract.brandName.trim(),
                      ].join(' • ').isNotEmpty
                          ? [
                              if (contract.categoryName.trim().isNotEmpty)
                                contract.categoryName.trim(),
                              if (contract.brandName.trim().isNotEmpty)
                                contract.brandName.trim(),
                            ].join(' • ')
                          : 'Confirmed Deal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    "₹${contract.dealAmount}",
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
                      contract.status.toUpperCase(),
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
}
