import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../controller/admin_dc_list_controller.dart';
import '../widgets/admin_challan_card.dart';

class AdminChallanListView extends StatelessWidget {
  const AdminChallanListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminDCListController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Delivery Challans",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: "Refresh List",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchChallans(isRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGold,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
        label: const Text(
          "Create DC",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        onPressed: () {
          Get.toNamed(AppRoutes.adminCreateDC)?.then((value) {
            if (value == true) {
              controller.fetchChallans(isRefresh: true);
            }
          });
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTabletOrDesktop = constraints.maxWidth >= 700;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: RefreshIndicator(
                color: AppTheme.primaryGold,
                onRefresh: () => controller.fetchChallans(isRefresh: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Search & Filter Section ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── KPI Summary Cards ────────────────────────────
                            _buildKpiMetrics(context, controller, isDark),
                            const SizedBox(height: 16),

                            // ── Search Bar ───────────────────────────────────
                            _buildSearchBar(context, controller, isDark),
                            const SizedBox(height: 14),

                            // ── Horizontal Filter Chips ──────────────────────
                            _buildFilterChips(context, controller, isDark),
                          ],
                        ),
                      ),
                    ),

                    // ── Challans List Section ────────────────────────────────
                    Obx(() {
                      if (controller.isLoading.value && controller.challans.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryGold),
                          ),
                        );
                      }

                      if (controller.filteredChallans.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(context, controller, isDark),
                        );
                      }

                      if (isTabletOrDesktop) {
                        // 2-Column Grid on Tablet/Desktop for maximum responsiveness
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 220,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final challan = controller.filteredChallans[index];
                                return AdminChallanCard(
                                  challan: challan,
                                  onTap: () {
                                    Get.toNamed(
                                      AppRoutes.adminDCDetails,
                                      arguments: challan.id,
                                    );
                                  },
                                );
                              },
                              childCount: controller.filteredChallans.length,
                            ),
                          ),
                        );
                      }

                      // Single-Column List for Mobile Phones
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final challan = controller.filteredChallans[index];
                              return AdminChallanCard(
                                challan: challan,
                                onTap: () {
                                  Get.toNamed(
                                    AppRoutes.adminDCDetails,
                                    arguments: challan.id,
                                  );
                                },
                              );
                            },
                            childCount: controller.filteredChallans.length,
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
    );
  }

  // ── KPI Summary Metrics ──────────────────────────────────────────────────
  Widget _buildKpiMetrics(
    BuildContext context,
    AdminDCListController controller,
    bool isDark,
  ) {
    return Obx(() {
      return Row(
        children: [
          _kpiCard("Total", controller.totalCount, AppTheme.primaryGold, isDark),
          const SizedBox(width: 8),
          _kpiCard("Pending", controller.pendingCount, const Color(0xFFD97706), isDark),
          const SizedBox(width: 8),
          _kpiCard("Dispatched", controller.dispatchedCount, const Color(0xFF2563EB), isDark),
          const SizedBox(width: 8),
          _kpiCard("Delivered", controller.deliveredCount, const Color(0xFF059669), isDark),
        ],
      );
    });
  }

  Widget _kpiCard(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2638) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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

  // ── Search Bar Widget ────────────────────────────────────────────────────
  Widget _buildSearchBar(
    BuildContext context,
    AdminDCListController controller,
    bool isDark,
  ) {
    final searchBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C394F) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: "Search by Challan, Truck, Buyer, Seller...",
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(IconlyLight.search, size: 20),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink();
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Filter Chips Bar ─────────────────────────────────────────────────────
  Widget _buildFilterChips(
    BuildContext context,
    AdminDCListController controller,
    bool isDark,
  ) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Draft'},
      {'key': 'dispatched', 'label': 'Dispatched'},
      {'key': 'delivered', 'label': 'Delivered'},
    ];

    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = controller.selectedStatus.value == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  f['label']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (_) => controller.setStatus(f['key']!),
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
    AdminDCListController controller,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
              ),
              child: Icon(
                IconlyLight.document,
                size: 48,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? "No matching challans found"
                  : "No Delivery Challans Yet",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.searchQuery.value.isNotEmpty
                  ? "Try changing your search terms or filters."
                  : "Delivery challans generated for contracts will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Refresh List"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGold,
                side: const BorderSide(color: AppTheme.primaryGold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => controller.fetchChallans(isRefresh: true),
            ),
          ],
        ),
      ),
    );
  }
}
