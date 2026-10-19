import 'package:flutter/material.dart';
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
                const SizedBox(height: 16),
                _buildSectionHeader(
                  context,
                  "Overview KPIs",
                  trailingText: "View All",
                  onTrailingTap: () => _showKpiDetails(context, data.kpis),
                ),
                const SizedBox(height: 16),
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
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const AppBarLeading(showBack: false),
      leadingWidth: AppBarLeading.widthFor(context, showBack: false),
      title: Image.asset(
        'assets/images/app_name.png',
        height: 32,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        // Real unread count instead of a fixed badge; reloads when returning from the list.
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
                      await Get.toNamed(AppRoutes.sellerNotifications);
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

  Widget _buildHeroSection(BuildContext context, SellerHeader header) {
    final theme = Theme.of(context);
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
              header.name,
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
            Icon(IconlyBold.home, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              header.branchName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "KYC: ${header.kycStatus.toUpperCase()}",
                style: GoogleFonts.inter(
                  fontSize: 10,
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

  Widget _buildTodaysOverview(BuildContext context, List<SellerKpi> kpis) {
    if (kpis.isEmpty) return const SizedBox();

    // All KPIs visible at once in a two-column grid (no sideways scrolling).
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis.map((kpi) {
            IconData icon = IconlyLight.document;
            if (kpi.type == 'currency') icon = IconlyLight.wallet;
            if (kpi.type == 'number') icon = IconlyLight.graph;
            return SizedBox(
              width: cardWidth,
              child: _buildDynamicMetricCard(context, kpi, icon),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDynamicMetricCard(
    BuildContext context,
    SellerKpi metric,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _openKpi(metric.screen),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
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
                style: GoogleFonts.inter(
                  fontSize: 10,
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric.subtitle,
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

  void _openKpi(String screen) {
    switch (screen) {
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
                    trailing: Text('${entry.value}'),
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
    double maxY = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 10;
    if (maxY == 0) maxY = 10;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
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
          const SizedBox(height: 12),
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
          ),
          const SizedBox(height: 8),
          if (labels.isNotEmpty)
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
        child: const SizedBox(
          height: 110,
          child: Center(child: Text("No Data")),
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

  Widget _buildRecentDeals(BuildContext context, List<SellerDeal> deals) {
    if (deals.isEmpty) return const Text("No recent deals.");

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
                      contract.buyerCompany,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ID: ${contract.contractId}",
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
