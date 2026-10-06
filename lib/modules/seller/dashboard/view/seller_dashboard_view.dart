import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controller/seller_dashboard_controller.dart';
import '../model/seller_dashboard_model.dart';
import '../../../../theme/glass_widgets.dart';
import '../../products/view/seller_product_view.dart';
import '../../products/view/add_product_view.dart';
import '../../products/controller/seller_product_controller.dart';
import '../../rfq/view/seller_rfq_list_view.dart';
import '../../contracts/view/seller_contracts_view.dart';
import '../../challans/view/seller_delivery_challan_view.dart';
import '../../branches/view/seller_branches_view.dart';
import '../../masters/view/seller_master_management_view.dart';
import '../../consignments/view/seller_consignments_view.dart';
import '../../buyer_offers/view/seller_buyer_offers_view.dart';
import '../../workspace/view/seller_workspace_view.dart';
import '../../../../services/notification_services.dart';
import '../../../../routes/app_routes.dart';

class SellerDashboardView extends StatelessWidget {
  SellerDashboardView({super.key});

  final SellerDashboardController controller = Get.put(SellerDashboardController());

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
                _buildSectionHeader(context, "Seller Workspace", trailingText: "View All", onTrailingTap: () => Get.to(() => const SellerWorkspaceView())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSimpleQuickCard(
                        context,
                        title: "Create Offer",
                        subtitle: "Publish a new listing",
                        icon: IconlyBold.plus,
                        color: Colors.orange,
                        onTap: _openCreateOffer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimpleQuickCard(
                        context,
                        title: "All Seller Tools",
                        subtitle: "Masters, deals & dispatch",
                        icon: IconlyBold.category,
                        color: Colors.blueGrey,
                        onTap: () => Get.to(() => const SellerWorkspaceView()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMyProductsQuickCard(context),
                const SizedBox(height: 12),
                _buildBuyerRfqQuickCard(context),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildContractsQuickCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildChallansQuickCard(context)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBranchesQuickCard(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMastersQuickCard(context)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSimpleQuickCard(
                        context,
                        title: "Consignments",
                        subtitle: "Ready for loading & dispatch",
                        icon: IconlyBold.buy,
                        color: Colors.teal,
                        onTap: () => Get.to(() => const SellerConsignmentsView()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSimpleQuickCard(
                        context,
                        title: "Buyer Offers",
                        subtitle: "Respond to buyer requests",
                        icon: IconlyBold.ticket,
                        color: Colors.indigo,
                        onTap: () => Get.to(() => const SellerBuyerOffersView()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader(context, "Overview KPIs", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildTodaysOverview(context, data.kpis),
                
                const SizedBox(height: 24),
                _buildSectionHeader(context, "Analytics Overview", trailingText: "View All"),
                const SizedBox(height: 16),
                _buildAnalyticsGrid(context, data.charts),

                const SizedBox(height: 24),
                _buildSectionHeader(context, "Recent Deals", trailingText: "View All", onTrailingTap: () => Get.to(() => const SellerBuyerOffersView())),
                const SizedBox(height: 16),
                _buildRecentDeals(context, data.recentDeals),

                const SizedBox(height: 24),
                _buildSectionHeader(
                  context,
                  "Recent Contracts",
                  trailingText: "View All",
                  onTrailingTap: () => Get.to(() => const SellerContractsView()),
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

  void _openCreateOffer() {
    if (!Get.isRegistered<SellerProductController>()) {
      Get.put(SellerProductController());
    }
    Get.to(() => const AddProductView());
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(IconlyLight.filter),
        onPressed: () {},
      ),
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
            future: NotificationServices.getUnreadCount().catchError((_) => 0),
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
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(IconlyLight.user_1, size: 16, color: Theme.of(context).colorScheme.primary),
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
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Text(
              header.name,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text("KYC: ${header.kycStatus.toUpperCase()}", style: GoogleFonts.inter(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyProductsQuickCard(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFFFFB300);

    return GestureDetector(
      onTap: () => Get.to(() => const SellerProductView()),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(IconlyBold.bag, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Products & Offers",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage offer stock, buyer negotiations & media",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(IconlyLight.arrow_right_2, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerRfqQuickCard(BuildContext context) {
    final theme = Theme.of(context);
    const accentColor = Color(0xFF2196F3);

    return GestureDetector(
      onTap: () => Get.to(() => const SellerRfqListView()),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(IconlyBold.document, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buyer Requirements (RFQs)",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "View buyer demands & submit seller quotes",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(IconlyLight.arrow_right_2, color: accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsQuickCard(BuildContext context) {
    final theme = Theme.of(context);
    const greenColor = Colors.green;

    return GestureDetector(
      onTap: () => Get.to(() => const SellerContractsView()),
      child: GlassCard(
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
                    color: greenColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyBold.document, color: greenColor, size: 20),
                ),
                const Icon(IconlyLight.arrow_right_2, color: greenColor, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Contracts",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Text(
              "Signed deal agreements",
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallansQuickCard(BuildContext context) {
    final theme = Theme.of(context);
    const purpleColor = Colors.purple;

    return GestureDetector(
      onTap: () => Get.to(() => const SellerDeliveryChallanView()),
      child: GlassCard(
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
                    color: purpleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyBold.work, color: purpleColor, size: 20),
                ),
                const Icon(IconlyLight.arrow_right_2, color: purpleColor, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Challans",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Text(
              "Dispatch & shipment",
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchesQuickCard(BuildContext context) {
    final theme = Theme.of(context);
    const blueColor = Colors.blue;

    return GestureDetector(
      onTap: () => Get.to(() => const SellerBranchesView()),
      child: GlassCard(
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
                    color: blueColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyBold.work, color: blueColor, size: 20),
                ),
                const Icon(IconlyLight.arrow_right_2, color: blueColor, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Branches",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Text(
              "Warehouse network",
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMastersQuickCard(BuildContext context) {
    final theme = Theme.of(context);
    const orangeColor = Colors.orange;

    return GestureDetector(
      onTap: () => Get.to(() => const SellerMasterManagementView()),
      child: GlassCard(
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
                    color: orangeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyBold.discount, color: orangeColor, size: 20),
                ),
                const Icon(IconlyLight.arrow_right_2, color: orangeColor, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Brands, Tags",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Text(
              "Your brand & tag detaile",
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleQuickCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(IconlyLight.arrow_right_2, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? trailingText, Widget? trailing, VoidCallback? onTrailingTap}) {
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
          GestureDetector(
            onTap: onTrailingTap,
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
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: kpis.map((kpi) {
          IconData icon = IconlyLight.document;
          if (kpi.type == 'currency') icon = IconlyLight.wallet;
          if (kpi.type == 'number') icon = IconlyLight.graph;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _buildDynamicMetricCard(context, kpi, icon),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDynamicMetricCard(BuildContext context, SellerKpi metric, IconData icon) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _openKpi(metric.screen),
      child: GlassCard(
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
                metric.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 4),
              Text(
                metric.type == 'currency' ? "₹${metric.value}" : metric.value.toString(),
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

  Widget _buildAnalyticsGrid(BuildContext context, SellerCharts charts) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPipelineCard(context, charts.dealPipeline)),
            const SizedBox(width: 12),
            Expanded(child: _buildDonutCard(context, "Commodity Mix", "Overall", charts.commodityMix)),
          ],
        ),
      ],
    );
  }

  Widget _buildPipelineCard(BuildContext context, Map<String, dynamic> pipeline) {
    final theme = Theme.of(context);
    
    final labels = pipeline.keys.toList();
    final values = pipeline.values.map((e) => (e as num).toDouble()).toList();
    double maxY = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 10;
    if (maxY == 0) maxY = 10;
    
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Deal Pipeline", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          Text("By Stage", style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 14,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Text(labels[idx].split(' ').first, style: TextStyle(fontSize: 6, color: theme.textTheme.bodyMedium?.color));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                      )
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

  Widget _buildDonutCard(BuildContext context, String title, String subtitle, List<CommodityMix> items) {
    final theme = Theme.of(context);
    final colors = [theme.colorScheme.primary, Colors.orangeAccent, Colors.redAccent, Colors.purpleAccent, Colors.blueAccent];
    
    if (items.isEmpty) {
       return GlassCard(
         padding: const EdgeInsets.all(12),
         child: const SizedBox(height: 110, child: Center(child: Text("No Data"))),
       );
    }
    
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
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Expanded(child: Text(e.value.categoryName, style: GoogleFonts.inter(fontSize: 8, color: theme.textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          Text("${e.value.volume.toInt()}%", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
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
                child: Icon(IconlyLight.swap, color: theme.colorScheme.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${deal.categoryName} - ${deal.brandName}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text("${deal.requestedQuantity} Tons", style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${deal.requestedAmount}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(deal.status.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentContracts(BuildContext context, List<SellerContract> contracts) {
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
                child: const Icon(IconlyLight.document, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract.buyerCompany, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    const SizedBox(height: 2),
                    Text("ID: ${contract.contractId}", style: GoogleFonts.inter(fontSize: 10, color: theme.textTheme.bodyMedium?.color)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${contract.dealAmount}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(contract.status.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
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
