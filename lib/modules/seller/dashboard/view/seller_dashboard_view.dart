import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agro_broker/modules/seller/dashboard/controller/seller_dashboard_controller.dart';
import 'package:agro_broker/modules/seller/dashboard/model/seller_dashboard_model.dart';

class SellerDashboardView extends StatelessWidget {
  const SellerDashboardView({super.key});

  static const Color primaryColor = Color(0xFFFFB300);
  static const Color accentColor = Color(0xFF1661EF);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerDashboardController());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(() {
          if (controller.isLoading.value || controller.dashboardData.value == null) {
            return const Text("Loading...");
          }
          final header = controller.dashboardData.value!.header;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back,",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
              ),
              Text(
                header.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(IconlyLight.notification, color: theme.iconTheme.color),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: primaryColor));
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
          color: primaryColor,
          backgroundColor: theme.cardColor,
          onRefresh: controller.fetchDashboardData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, data.header),
                const SizedBox(height: 24),
                _sectionTitle(context, "Overview KPIs"),
                const SizedBox(height: 12),
                _buildResponsiveKpiGrid(context, data.kpis),
                const SizedBox(height: 24),
                _buildResponsiveChartsSection(context, data.charts),
                const SizedBox(height: 24),
                _sectionTitle(context, "Recent Deals"),
                const SizedBox(height: 12),
                _buildRecentDealsList(context, data.recentDeals),
                const SizedBox(height: 24),
                _sectionTitle(context, "Recent Contracts"),
                const SizedBox(height: 12),
                _buildRecentContractsList(context, data.recentContracts),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, SellerHeader header) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.8),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(IconlyBold.home, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header.branchName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Code: ${header.branchCode} • KYC: ${header.kycStatus.toUpperCase()}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(IconlyLight.shield_done, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  "${header.profileCompletion}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResponsiveKpiGrid(BuildContext context, List<SellerKpi> kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt grid columns based on screen width
        int crossAxisCount = 2;
        double childAspectRatio = 1.3;

        if (constraints.maxWidth >= 900) {
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.4;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, index) {
            return _buildKpiCard(context, kpis[index]);
          },
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, SellerKpi kpi) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData getIconForType(String type) {
      switch (type) {
        case 'currency':
          return IconlyLight.wallet;
        case 'number':
          return IconlyLight.graph;
        default:
          return IconlyLight.document;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getIconForType(kpi.type),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: theme.iconTheme.color?.withOpacity(0.5),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kpi.type == 'currency' ? "₹${kpi.value}" : "${kpi.value}",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kpi.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveChartsSection(BuildContext context, SellerCharts charts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) {
          // Row for tablet/desktop
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDonutChart(context, charts.commodityMix)),
              const SizedBox(width: 16),
              Expanded(child: _buildPipelineChart(context, charts.dealPipeline)),
            ],
          );
        } else {
          // Column for mobile
          return Column(
            children: [
              _buildDonutChart(context, charts.commodityMix),
              const SizedBox(height: 24),
              _buildPipelineChart(context, charts.dealPipeline),
            ],
          );
        }
      },
    );
  }

  Widget _buildDonutChart(BuildContext context, List<CommodityMix> commodityMix) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (commodityMix.isEmpty) return const SizedBox();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Commodity Mix",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(commodityMix.length, (index) {
                  final mix = commodityMix[index];
                  return PieChartSectionData(
                    color: Colors.primaries[index % Colors.primaries.length],
                    value: mix.volume,
                    title: "${mix.volume}%",
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineChart(BuildContext context, Map<String, dynamic> pipeline) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (pipeline.isEmpty) return const SizedBox();

    final labels = pipeline.keys.toList();
    final values = pipeline.values.map((e) => (e as num).toDouble()).toList();
    double maxY = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 10;
    if (maxY == 0) maxY = 10;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Deal Pipeline",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[idx].split(' ').first, // Shortened
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(labels.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        width: 16,
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(4),
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

  Widget _buildRecentDealsList(BuildContext context, List<SellerDeal> deals) {
    if (deals.isEmpty) return const Text("No recent deals.");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: deals.length > 5 ? 5 : deals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deal = deals[index];
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(IconlyLight.swap, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${deal.categoryName} - ${deal.brandName}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Status: ${deal.status.replaceAll('_', ' ').toUpperCase()}",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${deal.requestedAmount}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${deal.requestedQuantity} Tons",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentContractsList(BuildContext context, List<SellerContract> contracts) {
    if (contracts.isEmpty) return const Text("No recent contracts.");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contracts.length > 5 ? 5 : contracts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(IconlyLight.document, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.buyerCompany,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${contract.contractId}",
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${contract.dealAmount}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contract.status.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
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
