import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../contracts/view/contract_view.dart';
import '../model/dashboard_model.dart';
import '../../../utils/money_format.dart';

class AdminOverviewKpisView extends StatefulWidget {
  final KpiModel kpis;
  final String initialCategory;

  const AdminOverviewKpisView({
    super.key,
    required this.kpis,
    this.initialCategory = 'All',
  });

  @override
  State<AdminOverviewKpisView> createState() => _AdminOverviewKpisViewState();
}

class _AdminOverviewKpisViewState extends State<AdminOverviewKpisView> {
  late String _selectedCategory;

  final List<String> _categories = const [
    'All',
    'Trading & Finance',
    'Contracts',
    'Logistics',
    'Network',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final k = widget.kpis;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Overview KPIs & Metrics",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Summary Header Card ──────────────────────────────────────
            _buildHeaderBanner(context, isDark),
            const SizedBox(height: 18),

            // ── Category Filter Chips ────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGold,
                      backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.grey.shade200,
                      onSelected: (val) {
                        if (val) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Category 1: Trading & Finance ────────────────────────────────
            if (_selectedCategory == 'All' || _selectedCategory == 'Trading & Finance') ...[
              _buildSectionTitle(context, "Trading & Finance"),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Gross Trade Value (GTV MTD)",
                value: formatInr(k.gtvMtd),
                subtitle: "Total turnover across executed deals this month",
                icon: IconlyLight.graph,
                accentColor: const Color(0xFF2563EB),
                isDark: isDark,
                actionLabel: "View Branch Reports",
                onActionTap: () => Get.toNamed(AppRoutes.adminBranchReports),
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Brokerage Earned (MTD)",
                value: formatInr(k.brokerageEarnedMtd),
                subtitle: "Platform brokerage revenue earned MTD",
                icon: IconlyLight.wallet,
                accentColor: const Color(0xFF059669),
                isDark: isDark,
                actionLabel: "View Brokerage Bills",
                onActionTap: () => Get.toNamed(AppRoutes.adminBrokerageBills),
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Average Brokerage Rate",
                value: "₹${k.brokerageRate} / Qtl",
                subtitle: "Weighted commission yield per quintal traded",
                icon: IconlyLight.discount,
                accentColor: const Color(0xFFD97706),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Payments Overdue",
                value: "${k.paymentsOverdue} Accounts",
                subtitle: "Parties with settlement delays beyond SLA terms",
                icon: IconlyLight.danger,
                accentColor: const Color(0xFFDC2626),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "At-Risk Financial Volume",
                value: formatInr(k.atRiskAmount),
                subtitle: "Total deal value currently flag-marked for delayed payment",
                icon: IconlyLight.shield_fail,
                accentColor: const Color(0xFFE11D48),
                isDark: isDark,
              ),
              const SizedBox(height: 22),
            ],

            // ── Category 2: Contracts & Deals ────────────────────────────────
            if (_selectedCategory == 'All' || _selectedCategory == 'Contracts') ...[
              _buildSectionTitle(context, "Contracts & Deals"),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Active Contracts",
                value: "${k.activeContracts}",
                subtitle: "B2B trading contracts currently open or in-progress",
                icon: IconlyLight.document,
                accentColor: AppTheme.primaryGold,
                isDark: isDark,
                actionLabel: "View All Contracts",
                onActionTap: () => Get.to(() => const ContractsScreen()),
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Pending Dispatches",
                value: "${k.pendingDispatches}",
                subtitle: "Shipments awaiting truck loading or delivery challan release",
                icon: IconlyLight.time_circle,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                actionLabel: "View Delivery Challans",
                onActionTap: () => Get.toNamed(AppRoutes.adminDeliveryChallans),
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Final Deals Closed (MTD)",
                value: "${k.finalDealsMtd}",
                subtitle: "Fully signed and verified deals this month",
                icon: IconlyLight.tick_square,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                actionLabel: "View Contract History",
                onActionTap: () => Get.toNamed(AppRoutes.adminContractHistory),
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Deals in Negotiation",
                value: "${k.dealsInNegotiation}",
                subtitle: "Live counter-offers between buyers and sellers",
                icon: IconlyLight.swap,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Avg Time to Contract (TTC)",
                value: "${k.avgTtcDays} Days",
                subtitle: "Average turnaround from offer placement to contract signature",
                icon: IconlyLight.calendar,
                accentColor: const Color(0xFF0284C7),
                isDark: isDark,
              ),
              const SizedBox(height: 22),
            ],

            // ── Category 3: Logistics & Operations ───────────────────────────
            if (_selectedCategory == 'All' || _selectedCategory == 'Logistics') ...[
              _buildSectionTitle(context, "Logistics & Operations"),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "On-Time Delivery (OTD %)",
                value: "${k.otdPercent % 1 == 0 ? k.otdPercent.toInt() : k.otdPercent}%",
                subtitle: "Percentage of shipments delivered within scheduled SLA",
                icon: IconlyLight.send,
                accentColor: const Color(0xFF059669),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Average Transit Time",
                value: "${k.avgTransitDays} Days",
                subtitle: "Mean transit duration between dispatch and warehouse receipt",
                icon: IconlyLight.location,
                accentColor: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Fleet Capacity Utilized",
                value: "${k.capacityUtilized % 1 == 0 ? k.capacityUtilized.toInt() : k.capacityUtilized}%",
                subtitle: "Percentage of contracted transport tonnage utilized",
                icon: IconlyLight.chart,
                accentColor: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Open Complaints & Issues",
                value: "${k.openComplaints}",
                subtitle: "Active tickets regarding quality, logistics or weight mismatch",
                icon: IconlyLight.info_circle,
                accentColor: const Color(0xFFEF4444),
                isDark: isDark,
                actionLabel: "View Notifications & Alerts",
                onActionTap: () => Get.toNamed(AppRoutes.notifications),
              ),
              const SizedBox(height: 22),
            ],

            // ── Category 4: Network & Ecosystem ──────────────────────────────
            if (_selectedCategory == 'All' || _selectedCategory == 'Network') ...[
              _buildSectionTitle(context, "Network & Ecosystem"),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Active Sellers",
                value: "${k.activeSellers}",
                subtitle: "Verified agro-processors, millers & stockists trading actively",
                icon: IconlyLight.user,
                accentColor: AppTheme.primaryGold,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Active Buyers",
                value: "${k.activeBuyers}",
                subtitle: "Procurement entities, distributors & FMCG buyers",
                icon: IconlyLight.user,
                accentColor: const Color(0xFF0284C7),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Active Transporters",
                value: "${k.activeTransporters}",
                subtitle: "Vetted freight operators and logistics fleet partners",
                icon: IconlyLight.work,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Operating Branches",
                value: "${k.branches}",
                subtitle: "Company regional branches & trading mandi desks",
                icon: IconlyLight.home,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                actionLabel: "Branch Performance",
                onActionTap: () => Get.toNamed(AppRoutes.adminBranchReports),
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Active Sub-Admins",
                value: "${k.adminsActive}",
                subtitle: "Team members with operational role privileges",
                icon: IconlyLight.profile,
                accentColor: const Color(0xFF64748B),
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailedKpiCard(
                context,
                title: "Listed Commodity SKUs",
                value: "${k.listedSkus}",
                subtitle: "Active pulses, grains & graded items on the board",
                icon: IconlyLight.category,
                accentColor: const Color(0xFFEC4899),
                isDark: isDark,
              ),
              const SizedBox(height: 22),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2638), const Color(0xFF111827)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IconlyBold.chart, color: AppTheme.primaryGold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Key Performance Indicators",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Real-time operational & business health metrics",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildDetailedKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                label: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
