import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import '../../../seller/categories/controller/seller_category_controller.dart';
import '../../../seller/categories/model/seller_category_model.dart';
import '../../../../theme/app_theme.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class TransporterCategoryView extends StatelessWidget {
  const TransporterCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SellerCategoryController());
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HeroHeader(
        title: "Categories",
        subtitle: "Agricultural commodity taxonomy",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: IconButton(
          icon: const Icon(IconlyLight.swap, color: Colors.white),
          tooltip: "Refresh",
          onPressed: controller.fetchAllData,
        ),
      ),
      body: Stack(
        children: [
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
          RefreshIndicator(
            onRefresh: controller.fetchAllData,
            color: primary,
            child: Obx(() {
              if (controller.isLoading.value && controller.categoryTree.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)));
              }

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboard(context, controller),
                    const SizedBox(height: 16),
                    _buildSearchBar(context, controller),
                    const SizedBox(height: 16),
                    controller.isSearching.value
                        ? _buildSearchResults(context, controller)
                        : _buildCategoryTree(context, controller),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, SellerCategoryController controller) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = controller.dashboardData.value;
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(IconlyBold.category, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                "Category Overview",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Total Categories", data.total.toString(), const Color(0xFFFF9800)),
              _buildStatItem("Root", data.root.toString(), const Color(0xFF2E7D32)),
              _buildStatItem("Sub Categories", data.sub.toString(), const Color(0xFFE65100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, SellerCategoryController controller) {
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
        onChanged: controller.search,
        style: GoogleFonts.inter(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: "Search categories...",
          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const Icon(IconlyLight.search, color: Color(0xFFFF9800), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, SellerCategoryController controller) {
    if (controller.searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No matching categories found", style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = controller.searchResults[index];
        return _buildCategoryTile(context, item.name, item.isActive);
      },
    );
  }

  Widget _buildCategoryTree(BuildContext context, SellerCategoryController controller) {
    if (controller.categoryTree.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No categories available", style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.categoryTree.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final node = controller.categoryTree[index];
        return _buildCategoryNode(context, node);
      },
    );
  }

  Widget _buildCategoryNode(BuildContext context, CategoryTreeModel node) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(IconlyLight.category, color: Color(0xFFFF9800), size: 18),
        ),
        title: Text(
          node.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          "${node.childrenCount} Subcategories",
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
        ),
        children: node.children.map((child) => _buildChildNode(context, child)).toList(),
      ),
    );
  }

  Widget _buildChildNode(BuildContext context, CategoryTreeModel child) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16, color: Color(0xFFFF9800)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              child.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF81C784), width: 0.8),
            ),
            child: const Text(
              "ACTIVE",
              style: TextStyle(color: Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String name, bool isActive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(IconlyLight.category, color: Color(0xFFFF9800), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? const Color(0xFF81C784) : const Color(0xFFFFB74D),
                width: 0.8,
              ),
            ),
            child: Text(
              isActive ? "ACTIVE" : "INACTIVE",
              style: TextStyle(
                color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
