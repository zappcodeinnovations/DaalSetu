import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../../theme/app_theme.dart';
import '../controller/transporter_brands_controller.dart';
import '../model/transporter_brand_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

class TransporterBrandsView extends StatelessWidget {
  TransporterBrandsView({super.key});

  final TransporterBrandsController controller = Get.put(TransporterBrandsController());
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Brands",
        subtitle: "Registered brands & catalog directory",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        trailing: IconButton(
          icon: const Icon(IconlyLight.swap, color: Colors.white),
          tooltip: "Refresh Brands",
          onPressed: () => controller.refreshAll(),
        ),
      ),
      body: Stack(
        children: [
          // Background watermark logo matching app theme
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/images/thumb_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Main scrollable content
          RefreshIndicator(
            onRefresh: () => controller.refreshAll(),
            color: primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DASHBOARD OVERVIEW SECTION
                  _buildSectionHeader(
                    context,
                    title: "Overview & Status",
                    icon: IconlyBold.star,
                    trailing: Obx(() {
                      if (controller.isDashboardLoading.value) {
                        return const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800)),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricsRow(context),

                  const SizedBox(height: 20),

                  // 2. SEARCH BAR
                  _buildSearchBar(context),

                  const SizedBox(height: 20),

                  // 3. BRANDS LIST / CATALOG SECTION
                  _buildBrandsSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Obx(() {
      final data = controller.dashboardData.value;
      final total = data?.totalBrands ?? 0;
      final active = data?.activeBrands ?? 0;
      final inUse = data?.brandsInUse ?? 0;

      return Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              context: context,
              title: "Total Brands",
              value: total.toString(),
              icon: IconlyLight.star,
              color: const Color(0xFFFF9800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              context: context,
              title: "Active Brands",
              value: active.toString(),
              icon: Icons.verified_outlined,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              context: context,
              title: "Brands in Use",
              value: inUse.toString(),
              icon: IconlyLight.work,
              color: const Color(0xFFE65100),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => controller.searchQuery.value = val,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: "Search brands by name...",
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(
            IconlyLight.search,
            size: 20,
            color: Color(0xFFFF9800),
          ),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                },
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

  Widget _buildBrandsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final brands = controller.filteredBrands;
      final totalInList = controller.brandsList.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Registered Brands",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  "${brands.length} ${brands.length == 1 ? 'Brand' : 'Brands'}",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (controller.isLoading.value && totalInList == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: Color(0xFFFF9800))),
            )
          else if (brands.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: brands.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final brand = brands[index];
                return _buildBrandCard(context, brand);
              },
            ),
        ],
      );
    });
  }

  Widget _buildBrandCard(BuildContext context, TransporterBrandModel brand) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBrandDetailSheet(context, brand),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Brand Monogram / Logo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF9800).withValues(alpha: 0.2),
                        const Color(0xFFF57C00).withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              brand.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildBrandInitial(brand),
                            ),
                          )
                        : _buildBrandInitial(brand),
                  ),
                ),
                const SizedBox(width: 14),

                // Brand Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (brand.companyName != null && brand.companyName!.isNotEmpty)
                        Text(
                          brand.companyName!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (brand.description != null && brand.description!.isNotEmpty)
                        Text(
                          brand.description!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          brand.isActive ? "Verified Brand" : "Registered Brand",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: brand.isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: brand.isActive
                          ? const Color(0xFF81C784)
                          : const Color(0xFFFFB74D),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    brand.isActive ? "ACTIVE" : "INACTIVE",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: brand.isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandInitial(TransporterBrandModel brand) {
    final initial = brand.name.isNotEmpty ? brand.name[0].toUpperCase() : "B";
    return Text(
      initial,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFE65100),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalBrandsCount = controller.dashboardData.value?.totalBrands ?? 0;
    final hasSearch = controller.searchQuery.value.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? IconlyLight.search : IconlyLight.star,
                size: 40,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? "No matching brands found" : "No brands listed yet",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? "Try searching with a different brand name."
                  : totalBrandsCount > 0
                      ? "The dashboard reports $totalBrandsCount total registered brand(s) in system metrics."
                      : "Master brands are managed centrally by the platform Super Admin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => controller.refreshAll(),
              icon: const Icon(IconlyLight.swap, size: 18),
              label: const Text("Refresh Catalog"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandDetailSheet(BuildContext context, TransporterBrandModel brand) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: _buildBrandInitial(brand)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (brand.companyName != null)
                          Text(
                            brand.companyName!,
                            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: brand.isActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: brand.isActive
                            ? const Color(0xFF81C784)
                            : const Color(0xFFFFB74D),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      brand.isActive ? "ACTIVE" : "INACTIVE",
                      style: TextStyle(
                        color: brand.isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (brand.description != null && brand.description!.isNotEmpty) ...[
                Text(
                  "Description",
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  brand.description!,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
