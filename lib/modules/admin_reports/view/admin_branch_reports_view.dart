import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../theme/app_theme.dart';
import '../controller/admin_reports_controller.dart';
import '../widgets/branch_report_card.dart';

class AdminBranchReportsView extends StatelessWidget {
  const AdminBranchReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminReportsController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        controller.searchFocusNode.unfocus();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => controller.searchFocusNode.unfocus(),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                controller.searchFocusNode.unfocus();
                Get.back();
              },
            ),
            title: Text(
              "Branch Reports",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              // Export Action Button
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _openExportBottomSheet(context, controller, isDark),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text(
                    "Export",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
              IconButton(
                tooltip: "Refresh Data",
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => controller.fetchReports(isRefresh: true),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isTabletOrDesktop = constraints.maxWidth >= 700;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: RefreshIndicator(
                    color: AppTheme.primaryGold,
                    onRefresh: () => controller.fetchReports(isRefresh: true),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top KPI Metrics ──────────────────────────────
                            _buildKpiMetrics(context, controller, isDark),
                            const SizedBox(height: 16),

                            // ── Date Range Horizontal Filter ─────────────────
                            _buildDateFilterChips(context, controller, isDark),
                            const SizedBox(height: 12),

                            // ── Search Bar ───────────────────────────────────
                            _buildSearchBar(context, controller, isDark),
                            const SizedBox(height: 12),

                            // ── Branch Selector Horizontal Filter ────────────
                            _buildBranchFilterChips(context, controller, isDark),
                          ],
                        ),
                      ),
                    ),

                    // ── Branch Cards List Section ────────────────────────────
                    Obx(() {
                      if (controller.isLoading.value && controller.reports.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryGold),
                          ),
                        );
                      }

                      if (controller.filteredReports.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(context, controller, isDark),
                        );
                      }

                      if (isTabletOrDesktop) {
                        // 2-Column Responsive Grid on Tablet / Desktop
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 250,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final report = controller.filteredReports[index];
                                return BranchReportCard(report: report);
                              },
                              childCount: controller.filteredReports.length,
                            ),
                          ),
                        );
                      }

                      // Single-Column Responsive List on Mobile
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final report = controller.filteredReports[index];
                              return BranchReportCard(report: report);
                            },
                            childCount: controller.filteredReports.length,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  ),
);
  }

  // ── KPI Summary Cards ────────────────────────────────────────────────────
  Widget _buildKpiMetrics(
    BuildContext context,
    AdminReportsController controller,
    bool isDark,
  ) {
    return Obx(() {
      return Row(
        children: [
          _kpiCard(
            "Total GTV",
            controller.totalGtvFormatted,
            AppTheme.primaryGold,
            isDark,
          ),
          const SizedBox(width: 8),
          _kpiCard(
            "Contracts",
            "${controller.totalContractsCount} Deals",
            const Color(0xFF2563EB),
            isDark,
          ),
          const SizedBox(width: 8),
          _kpiCard(
            "Avg OTD",
            "${controller.avgOtdPercent}%",
            const Color(0xFF059669),
            isDark,
          ),
          const SizedBox(width: 8),
          _kpiCard(
            "Branches",
            "${controller.totalBranchesCount}",
            const Color(0xFFD97706),
            isDark,
          ),
        ],
      );
    });
  }

  Widget _kpiCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2638) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Date Range Filter Chips ──────────────────────────────────────────────
  Widget _buildDateFilterChips(
    BuildContext context,
    AdminReportsController controller,
    bool isDark,
  ) {
    final ranges = ['Today', 'This Week', 'Month (MTD)', 'All Time'];

    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ranges.map((r) {
            final isSelected = controller.selectedDateRange.value == r;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  r,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.black
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryGold,
                backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryGold
                      : (isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0)),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (_) => controller.setDateRange(r),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ── Search Bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar(
    BuildContext context,
    AdminReportsController controller,
    bool isDark,
  ) {
    final searchBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: searchBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller.searchController,
        focusNode: controller.searchFocusNode,
        onChanged: controller.onSearchChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => controller.searchFocusNode.unfocus(),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "Search branch city or manager name...",
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(IconlyLight.search, size: 18),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink();
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ── Branch Selector Chips ────────────────────────────────────────────────
  Widget _buildBranchFilterChips(
    BuildContext context,
    AdminReportsController controller,
    bool isDark,
  ) {
    return Obx(() {
      final branches = controller.availableBranches;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: branches.map((b) {
            final isSelected = controller.selectedBranch.value == b;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(
                  b,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF2563EB),
                backgroundColor: isDark ? const Color(0xFF161D2B) : const Color(0xFFF1F5F9),
                showCheckmark: false,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (_) => controller.setBranchFilter(b),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(
    BuildContext context,
    AdminReportsController controller,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 14),
            Text(
              "No branch reports match your filter",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Try changing your search keyword or selected date range.",
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text("Refresh Reports"),
              onPressed: () => controller.fetchReports(isRefresh: true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Export Bottom Sheet ──────────────────────────────────────────────────
  void _openExportBottomSheet(
    BuildContext context,
    AdminReportsController controller,
    bool isDark,
  ) {
    controller.searchFocusNode.unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2638) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Export Branch Performance Report",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose format to download or share with your team:",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              // Option 1: CSV / Excel
              _exportOptionTile(
                icon: Icons.table_chart_rounded,
                iconColor: const Color(0xFF059669),
                title: "Export as CSV / Excel Spreadsheet",
                subtitle: "Formatted table with GTV, deals, OTD %, and manager details",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  controller.exportCsv();
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Share Summary Text
              _exportOptionTile(
                icon: Icons.share_rounded,
                iconColor: const Color(0xFF2563EB),
                title: "Share Summary Message",
                subtitle: "Formatted summary message ready for WhatsApp or Email",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  controller.exportSummaryText();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _exportOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161D2B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}
